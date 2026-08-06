import sys
import os
import markdown
from weasyprint import HTML


def convertir(md_path):
    if not os.path.exists(md_path):
        print(f"Error: El archivo {md_path} no existe.")
        sys.exit(1)

    base_name = os.path.splitext(md_path)[0]
    html_path = f"{base_name}.html"
    pdf_path = f"{base_name}.pdf"

    # Leer Markdown
    with open(md_path, "r", encoding="utf-8") as f:
        text = f.read()

    # Convertir a HTML con extensiones útiles (tablas, bloques de código, etc.)
    html_body = markdown.markdown(
        text, extensions=["fenced_code", "tables", "sane_lists"]
    )

    # Plantilla HTML con estilos CSS embebidos profesionales
    html_content = f"""<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <style>
        @page {{
            size: A4;
            margin: 20mm 18mm;
            background-color: #fcfcfd;
            @bottom-right {{
                content: "Página " counter(page) " de " counter(pages);
                font-family: 'Helvetica Neue', Arial, sans-serif;
                font-size: 8pt;
                color: #718096;
            }}
        }}
        body {{
            font-family: 'Georgia', serif;
            color: #2d3748;
            line-height: 1.6;
            font-size: 10pt;
            margin: 0;
        }}
        h1, h2, h3 {{
            font-family: 'Helvetica Neue', Arial, sans-serif;
            color: #1a365d;
        }}
        h1 {{ font-size: 18pt; border-bottom: 2px solid #2b6cb0; padding-bottom: 6px; }}
        h2 {{ font-size: 13pt; border-bottom: 1px solid #e2e8f0; padding-bottom: 4px; margin-top: 20px; }}
        pre {{
            background-color: #f7fafc;
            border: 1px solid #e2e8f0;
            padding: 10px;
            border-radius: 5px;
            font-family: monospace;
            font-size: 9pt;
        }}
        code {{
            background-color: #edf2f7;
            padding: 2px 4px;
            border-radius: 3px;
            font-size: 9pt;
        }}
        blockquote {{
            border-left: 4px solid #3182ce;
            margin: 0;
            padding-left: 12px;
            color: #4a5568;
            font-style: italic;
        }}
        table {{
            width: 100%;
            border-collapse: collapse;
            margin: 15px 0;
        }}
        th, td {{
            border: 1px solid #e2e8f0;
            padding: 8px 12px;
            font-size: 9pt;
        }}
        th {{
            background-color: #edf2f7;
            color: #2b6cb0;
        }}
    </style>
</head>
<body>
    {html_body}
</body>
</html>
"""

    # Escribir HTML temporal y compilar a PDF con WeasyPrint
    with open(html_path, "w", encoding="utf-8") as f:
        f.write(html_content)

    HTML(html_path).write_pdf(pdf_path)

    # Limpiar archivo HTML temporal
    os.remove(html_path)
    print(f"¡PDF generado con éxito: {pdf_path}!")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: md2pdf <archivo.md>")
        sys.exit(1)
    convertir(sys.argv[1])
