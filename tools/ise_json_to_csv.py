import json
import csv
import os

def json_to_csv():
    json_path = 'output/json/info_security_equip_assessment_result.json'
    csv_path = 'output/csv/info_security_equip_assessment_result.csv'
    
    if not os.path.exists(json_path):
        print(f"Error: {json_path} not found")
        # Create header even if empty
        with open(csv_path, 'w', encoding='utf-8-sig', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(['assessment_id', 'profile', 'id', 'source_id', 'title', 'status', 'reason'])
        return

    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    results = data.get('results', [])
    
    with open(csv_path, 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f)
        header = ['assessment_id', 'profile', 'id', 'source_id', 'title', 'risk_level', 'severity_label', 'status', 'reason', 'script_path', 'exit_code', 'evidence_count', 'legal_basis', 'supervisory_regulation', 'detailed_rule', 'recommendation', 'error_message']
        writer.writerow(header)
        
        for r in results:
            writer.writerow([
                data.get('assessment_id', 'N/A'),
                r.get('profile', 'N/A'),
                r.get('id', 'N/A'),
                r.get('source_id', 'N/A'),
                r.get('title', 'N/A'),
                r.get('risk_level', 'N/A'),
                r.get('severity_label', 'N/A'),
                r.get('status', 'N/A'),
                r.get('reason', 'N/A'),
                r.get('script', {}).get('path', 'N/A'),
                r.get('script', {}).get('exit_code', 'N/A'),
                len(r.get('evidence', [])),
                r.get('legal_mapping', {}).get('electronic_financial_transaction_act', 'N/A'),
                r.get('legal_mapping', {}).get('supervisory_regulation', 'N/A'),
                r.get('legal_mapping', {}).get('detailed_rule', 'N/A'),
                r.get('recommendation', 'N/A'),
                r.get('error_message', '')
            ])

if __name__ == "__main__":
    json_to_csv()
