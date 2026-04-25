import json
import os

def json_to_html():
    json_path = 'output/json/info_security_equip_assessment_result.json'
    html_path = 'output/html/info_security_equip_report.html'
    
    if not os.path.exists(json_path):
        print(f"Error: {json_path} not found")
        data = {"results": [], "summary": {"total": 0, "pass": 0, "fail": 0}}
    else:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

    # Simplified HTML generation without Jinja2 for robustness in Phase 0
    html_template = """
    <!DOCTYPE html>
    <html lang="ko">
    <head>
        <meta charset="UTF-8">
        <title>ISE Diagnosis Report</title>
        <link rel="stylesheet" href="../../templates/ise_style.css">
        <style>
            body { font-family: sans-serif; margin: 20px; }
            table { width: 100%; border-collapse: collapse; margin-top: 20px; }
            th, td { border: 1px solid #ccc; padding: 10px; text-align: left; }
            th { background-color: #f4f4f4; }
            .status-PASS { color: green; font-weight: bold; }
            .status-FAIL { color: red; font-weight: bold; }
            .status-ERROR { color: darkred; font-weight: bold; }
            .status-MANUAL_REVIEW { color: orange; font-weight: bold; }
            .status-EVIDENCE_MISSING { color: purple; font-weight: bold; }
        </style>
    </head>
    <body>
        <h1>정보보호시스템 진단 결과 보고서 (Phase 0)</h1>
        <p>생성일시: {generated_at}</p>
        
        <h2>전체 결과 요약</h2>
        <table>
            <tr>
                <th>전체 항목</th>
                <th>양호(PASS)</th>
                <th>취약(FAIL)</th>
                <th>수동점검(MANUAL)</th>
                <th>증적부족(MISSING)</th>
                <th>오류(ERROR)</th>
            </tr>
            <tr>
                <td>{total}</td>
                <td>{pass_count}</td>
                <td>{fail_count}</td>
                <td>{manual_count}</td>
                <td>{missing_count}</td>
                <td>{error_count}</td>
            </tr>
        </table>

        <h2>상세 진단 결과</h2>
        <table>
            <tr>
                <th>ID</th>
                <th>항목명</th>
                <th>프로파일</th>
                <th>상태</th>
                <th>진단 근거</th>
            </tr>
            {result_rows}
        </table>
    </body>
    </html>
    """

    results = data.get('results', [])
    rows = ""
    for r in results:
        status = r.get('status', 'UNKNOWN')
        rows += f"""
        <tr>
            <td>{r.get('id', '')}</td>
            <td>{r.get('title', '')}</td>
            <td>{r.get('profile', '')}</td>
            <td class="status-{status}">{status}</td>
            <td>{r.get('reason', '')}</td>
        </tr>
        """

    summary = data.get('summary', {})
    html_content = html_template.format(
        generated_at=data.get('generated_at', 'N/A'),
        total=summary.get('total', 0),
        pass_count=summary.get('pass', 0),
        fail_count=summary.get('fail', 0),
        manual_count=summary.get('manual_review', 0),
        missing_count=summary.get('evidence_missing', 0),
        error_count=summary.get('error', 0),
        result_rows=rows
    )

    with open(html_path, 'w', encoding='utf-8') as f:
        f.write(html_content)
    print(f"Report generated: {html_path}")

if __name__ == "__main__":
    json_to_html()
