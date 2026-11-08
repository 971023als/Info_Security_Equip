#!/usr/bin/env python3
"""Merge one check result into the ISE assessment result JSON.

Reads a single-result entry (produced by the runner), enriches it with
catalog metadata, upserts it into output/json/info_security_equip_assessment_result.json,
recomputes the summary, and writes the file atomically.
"""
import argparse
import json
import os
import tempfile

SUMMARY_KEYS = {
    'PASS': 'pass',
    'FAIL': 'fail',
    'MANUAL_REVIEW': 'manual_review',
    'EVIDENCE_MISSING': 'evidence_missing',
    'ERROR': 'error',
    'NOT_IMPLEMENTED': 'not_implemented',
    'NA': 'na',
}


def load_json(path, default):
    try:
        with open(path, encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        return default


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--result-file', required=True)
    ap.add_argument('--entry-file', required=True, help='JSON file with one check entry')
    ap.add_argument('--catalog', default='info_security_equip_check_catalog.json')
    args = ap.parse_args()

    entry = load_json(args.entry_file, None)
    if not isinstance(entry, dict) or not entry.get('id'):
        raise SystemExit(f'invalid entry file: {args.entry_file}')

    catalog = load_json(args.catalog, [])
    meta = next((c for c in catalog if c.get('id') == entry['id']), {})

    record = {
        'profile': entry.get('profile', ''),
        'id': entry['id'],
        'source_id': meta.get('source_id', ''),
        'title': meta.get('title', ''),
        'risk_level': meta.get('risk_level', ''),
        'severity_label': meta.get('severity_label', ''),
        'status': entry.get('status', 'ERROR'),
        'reason': entry.get('reason', ''),
        'script': entry.get('script', {}),
        'evidence': entry.get('evidence', []),
        'legal_mapping': {
            'electronic_financial_transaction_act': meta.get('legal_basis', ''),
            'supervisory_regulation': meta.get('supervisory_regulation', ''),
            'detailed_rule': meta.get('detailed_rule', ''),
        },
        'recommendation': meta.get('recommendation', ''),
        'error_message': entry.get('error_message', ''),
    }

    data = load_json(args.result_file, {})
    results = data.get('results', [])
    if not isinstance(results, list) or not all(isinstance(x, dict) for x in results):
        raise SystemExit('Invalid existing result data; refusing to replace it')
    results = [r for r in results
               if not (r.get('profile') == record['profile'] and r.get('id') == record['id'])]
    results.append(record)

    summary = {'total': len(results)}
    for key in SUMMARY_KEYS.values():
        summary[key] = 0
    for r in results:
        key = SUMMARY_KEYS.get(str(r.get('status', '')).upper())
        if key:
            summary[key] += 1

    from datetime import datetime, timezone
    out = {
        'assessment_id': data.get('assessment_id') or 'ISE-' + datetime.now(timezone.utc).strftime('%Y%m%d'),
        'generated_at': datetime.now(timezone.utc).isoformat(),
        'results': results,
        'summary': summary,
    }

    os.makedirs(os.path.dirname(args.result_file) or '.', exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(args.result_file) or '.', suffix='.tmp')
    with os.fdopen(fd, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    os.replace(tmp, args.result_file)
    print(f"recorded {record['profile']}/{record['id']}: {record['status']} (total {summary['total']})")


if __name__ == '__main__':
    main()
