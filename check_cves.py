#!/usr/bin/env python3

import csv
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

def main():
    # Получаем пути к файлам
    if len(sys.argv) < 2:
        print(f"Использование: {sys.argv[0]} <csv_file> [docx_file]")
        print(f"Или установите переменную окружения {DEFAULT_DOCX_ENV}")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    
    # Определяем DOCX файл
    if len(sys.argv) >= 3:
        docx_file = sys.argv[2]
    elif DEFAULT_DOCX_ENV in os.environ:
        docx_file = os.environ[DEFAULT_DOCX_ENV]
    else:
        print(f"Ошибка: не указан DOCX файл и отсутствует переменная {DEFAULT_DOCX_ENV}")
        sys.exit(1)

    # Проверяем существование файлов
    if not os.path.exists(csv_file):
        print(f"Ошибка: CSV файл не найден: {csv_file}")
        sys.exit(1)
    
    if not os.path.exists(docx_file):
        print(f"Ошибка: DOCX файл не найден: {docx_file}")
        sys.exit(1)

    try:
        with open(csv_file, newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f, delimiter=';')
            if 'VulnerabilityID' not in reader.fieldnames:
                print('Ошибка: колонка VulnerabilityID не найдена в CSV')
                sys.exit(1)

                    # ANSI коды для цветов
            RED = '\033[91m'
            GREEN = '\033[92m'
            RESET = '\033[0m'
            
            print("\nПроверка CVE в документе:")
            print("-" * 60)
            print(f"DOCX файл: {docx_file}")
            print(f"CSV файл: {csv_file}")
            print("-" * 60)
            print(f"{'№':<5} | {'VulnerabilityID':<20} | {'Статус':<12}")
            print("-" * 60)
            

            for index, row in enumerate(reader, 1):
                cve = row['VulnerabilityID'].strip('"')
                found = search_in_docx(docx_file, cve)
                if found:
                   status = f"{GREEN}Найдено{RESET}"
                else:
                   status = f"{RED}Не найдено{RESET}"
                print(f"{index:<5} | {cve:<20} | {status:<{12 + len(RED) + len(RESET)}}")
                
    except Exception as e:
        print(f'\nОшибка: {str(e)}', file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()