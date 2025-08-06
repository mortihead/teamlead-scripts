#!/usr/bin/env python3

"""
Проверка наличия уязвимостей (CVE-*, CSPW-*) в DOCX файле на основе их списка из PDF.

Требуемые зависимости:

=== Для всех ОС ===
1. Python 3.x
2. PyPDF2 (если pdftotext недоступен):
   pip install PyPDF2

=== Linux (Ubuntu/Debian) ===
1. pdftotext (рекомендуется):
   sudo apt install poppler-utils
2. Для DOCX (если textutil недоступен):
   sudo apt install python3-python-docx

=== macOS === 
1. pdftotext (рекомендуется):
   brew install poppler
2. textutil (встроен в систему)

=== Windows ===
1. pdftotext (рекомендуется):
   - Скачать poppler для Windows: https://github.com/oschwartz10612/poppler-windows/releases/
   - Добавить папку с pdftotext.exe в PATH
2. Для DOCX установите:
   pip install python-docx
"""

import re
import subprocess
import sys
import os
import tempfile
import shlex

# Конфигурация по умолчанию
DEFAULT_DOCX_ENV = 'SCA_DOCX'

def search_in_docx(docx_path, text):
    try:
        with tempfile.NamedTemporaryFile(suffix='.txt') as tmp:
            safe_docx_path = shlex.quote(docx_path)
            safe_tmp_path = shlex.quote(tmp.name)
            
            cmd = f"textutil -convert txt -output {safe_tmp_path} {safe_docx_path}"
            subprocess.run(cmd, shell=True, check=True, stderr=subprocess.DEVNULL)
            
            with open(tmp.name, 'r', encoding='utf-8') as f:
                return text in f.read()
    except Exception as e:
        print(f"Ошибка при обработке DOCX: {str(e)}", file=sys.stderr)
        return False

def extract_vulnerabilities_from_pdf(pdf_path):
    try:
        with tempfile.NamedTemporaryFile(suffix='.txt') as tmp:
            safe_pdf_path = shlex.quote(pdf_path)
            safe_tmp_path = shlex.quote(tmp.name)
            
            cmd = f"pdftotext {safe_pdf_path} {safe_tmp_path}"
            subprocess.run(cmd, shell=True, check=True, stderr=subprocess.DEVNULL)
            
            with open(tmp.name, 'r', encoding='utf-8', errors='ignore') as f:
                text = f.read()
                # Ищем все CVE-* и CSPW-* уязвимости
                return set(re.findall(r'\b(CVE-\d{4}-\d{4,}|CSPW-\d{3,})\b', text, re.IGNORECASE))
    except Exception as e:
        print(f"Ошибка при обработке PDF: {str(e)}", file=sys.stderr)
        return set()

def main():
    # Получаем пути к файлам
    if len(sys.argv) < 2:
        print(f"Использование: {sys.argv[0]} <pdf_file> [docx_file]")
        print(f"Или установите переменную окружения {DEFAULT_DOCX_ENV}")
        sys.exit(1)
    
    pdf_file = sys.argv[1]
    
    # Определяем DOCX файл
    if len(sys.argv) >= 3:
        docx_file = sys.argv[2]
    elif DEFAULT_DOCX_ENV in os.environ:
        docx_file = os.environ[DEFAULT_DOCX_ENV]
    else:
        print(f"Ошибка: не указан DOCX файл и отсутствует переменная {DEFAULT_DOCX_ENV}")
        sys.exit(1)

    # Проверяем существование файлов
    if not os.path.exists(pdf_file):
        print(f"Ошибка: PDF файл не найден: {pdf_file}")
        sys.exit(1)
    
    if not os.path.exists(docx_file):
        print(f"Ошибка: DOCX файл не найден: {docx_file}")
        sys.exit(1)

    try:
        # Извлекаем уязвимости из PDF
        vulnerabilities = extract_vulnerabilities_from_pdf(pdf_file)
        
        if not vulnerabilities:
            print("В PDF файле не найдено уязвимостей формата CVE-* или CSPW-*")
            sys.exit(0)

        # ANSI коды для цветов
        RED = '\033[91m'
        GREEN = '\033[92m'
        RESET = '\033[0m'
        
        print("\nПроверка уязвимостей в документе:")
        print("-" * 60)
        print(f"PDF файл (источник уязвимостей): {pdf_file}")
        print(f"DOCX файл для проверки: {docx_file}")
        print("-" * 60)
        print(f"{'№':<5} | {'VulnerabilityID':<20} | {'Статус':<12}")
        print("-" * 60)
        
        for index, vuln in enumerate(sorted(vulnerabilities), 1):
            found = search_in_docx(docx_file, vuln)
            if found:
                status = f"{GREEN}Найдено{RESET}"
            else:
                status = f"{RED}Не найдено{RESET}"
            print(f"{index:<5} | {vuln:<20} | {status:<{12 + len(RED) + len(RESET)}}")
            
    except Exception as e:
        print(f'\nОшибка: {str(e)}', file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()