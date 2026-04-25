import json
catalog = []
profiles_all = ['fw', 'vpn', 'ids', 'ips', 'ddos', 'waf']
for i in range(1, 44):
    id_str = f'ISE-{i:03d}'
    item = {
        'id': id_str,
        'source_id': str(i),
        'title': f'정보보호시스템 진단 항목 {id_str}',
        'profiles': profiles_all,
        'risk_level': 3,
        'severity_label': 'MEDIUM',
        'legal_basis': '전자금융거래법 제21조',
        'supervisory_regulation': '전자금융감독규정 제15조',
        'detailed_rule': '전자금융감독규정 시행세칙',
        'description': f'{id_str} 항목에 대한 상세 설명 및 진단 기준',
        'audit_method': 'evidence_file',
        'evidence_required': True,
        'script_path': 'shell_scirpt/info_security_equip/{profile}/' + id_str + '.sh',
        'recommendation': '관련 법령 및 규정에 따른 기술적 보호대책 강화를 권고함'
    }
    if i == 1:
        item.update({'title': '보안장비 정책 및 로그 백업 설정 여부', 'risk_level': 4, 'severity_label': 'HIGH'})
    elif i == 2:
        item.update({'title': '원격 로그 서버 사용 여부', 'risk_level': 4, 'severity_label': 'HIGH'})
    elif i == 3:
        item.update({'title': 'DMZ 구간 설정 여부', 'profiles': ['fw', 'vpn'], 'risk_level': 4, 'severity_label': 'HIGH'})
    catalog.append(item)

with open('info_security_equip_check_catalog.json', 'w', encoding='utf-8') as f:
    json.dump(catalog, f, indent=2, ensure_ascii=False)
