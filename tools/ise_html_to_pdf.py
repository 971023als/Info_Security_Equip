import os
import sys

def html_to_pdf():
    html_path = 'output/html/info_security_equip_report.html'
    pdf_path = 'output/pdf/info_security_equip_report.pdf'
    
    if not os.path.exists(html_path):
        print(f"Error: {html_path} not found")
        return

    print("Checking for PDF generation libraries...")
    
    # Try WeasyPrint
    try:
        from weasyprint import HTML
        HTML(html_path).write_pdf(pdf_path)
        print(f"PDF generated successfully using WeasyPrint: {pdf_path}")
        return
    except ImportError:
        print("WeasyPrint not found.")
    
    # Try Playwright
    try:
        import asyncio
        from playwright.sync_api import sync_playwright
        
        with sync_playwright() as p:
            browser = p.chromium.launch()
            page = browser.new_page()
            page.goto(f"file://{os.path.abspath(html_path)}")
            page.pdf(path=pdf_path, format="A4")
            browser.close()
        print(f"PDF generated successfully using Playwright: {pdf_path}")
        return
    except ImportError:
        print("Playwright not found.")
    except Exception as e:
        print(f"Playwright error: {e}")

    print("-" * 50)
    print("CRITICAL: No PDF generation library (WeasyPrint or Playwright) is available.")
    print("Please install one of them to enable PDF reporting:")
    print("  pip install weasyprint")
    print("  OR")
    print("  pip install playwright && playwright install chromium")
    print("-" * 50)

if __name__ == "__main__":
    html_to_pdf()
