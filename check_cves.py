#!/usr/bin/env python3

import csv
import subprocess
import sys
import os
import tempfile
import shlex
import re

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

def extract_cvss_score(row):
    """Извлекает CVSS score из строки CSV, обрабатывая разные форматы"""
    # Сначала пробуем CVSSv3
    cvss_field = row.get('CVSSv3', '') or row.get('CVSSv3 Score', '') or row.get('CVSSv3_Score', '')
    if not cvss_field:
        # Если CVSSv3 нет, пробуем CVSSv2
        cvss_field = row.get('CVSSv2', '') or row.get('CVSSv2 Score', '') or row.get('CVSSv2_Score', '')
    
    # Очищаем строку от кавычек и лишних символов
    cvss_field = str(cvss_field).strip('"\' ')
    
    # Пытаемся извлечь числовое значение
    match = re.search(r'(\d+\.\d+)', cvss_field)
    if match:
        return float(match.group(1))
    try:
        return float(cvss_field)
    except (ValueError, TypeError):
        return None

def get_severity_level(score):
    """Определяет уровень критичности на основе CVSS score"""
    if score is None:
        return "N/A"
    if score >= 9.0:
        return "Critical"
    elif score >= 7.0:
        return "High"
    elif score >= 4.0:
        return "Medium"
    elif score > 0:
        return "Low"
    return "None"

def main():
    if len(sys.argv) < 2:
        print(f"Использование: {sys.argv[0]} <csv_file> [docx_file]")
        print(f"Или установите переменную окружения {DEFAULT_DOCX_ENV}")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    
    if len(sys.argv) >= 3:
        docx_file = sys.argv[2]
    elif DEFAULT_DOCX_ENV in os.environ:
        docx_file = os.environ[DEFAULT_DOCX_ENV]
    else:
        print(f"Ошибка: не указан DOCX файл и отсутствует переменная {DEFAULT_DOCX_ENV}")
        sys.exit(1)

    if not os.path.exists(csv_file):
        print(f"Ошибка: CSV файл не найден: {csv_file}")
        sys.exit(1)
    
    if not os.path.exists(docx_file):
        print(f"Ошибка: DOCX файл не найден: {docx_file}")
        sys.exit(1)

    try:
        with open(csv_file, newline='', encoding='utf-8') as f:
            # Автоопределение разделителя
            dialect = csv.Sniffer().sniff(f.read(1024))
            f.seek(0)
            reader = csv.DictReader(f, delimiter=dialect.delimiter)
            
            if 'VulnerabilityID' not in reader.fieldnames:
                print('Ошибка: колонка VulnerabilityID не найдена в CSV')
                sys.exit(1)

            # Цвета
            RED = '\033[91m'
            GREEN = '\033[92m'
            YELLOW = '\033[93m'
            BLUE = '\033[94m'
            RESET = '\033[0m'
            
            # Заголовок таблицы
            print("\nПроверка CVE в документе:")
            print("-" * 85)
            print(f"DOCX файл: {docx_file}")
            print(f"CSV файл: {csv_file}")
            print("-" * 85)
            print(f"{'№':<5} | {'VulnerabilityID':<20} | {'Статус':<12} | {'Уровень':<29} | {'CVSS':<6}")
            print("-" * 85)
            
            for index, row in enumerate(reader, 1):
                cve = str(row['VulnerabilityID']).strip('"\' ')
                found = search_in_docx(docx_file, cve)
                
                # Получаем CVSS score
                cvss_score = extract_cvss_score(row)
                severity = get_severity_level(cvss_score)
                
                # Форматируем статус
                if found:
                    status = f"{GREEN}Найдено{RESET}"
                    severity_display = "-"
                    cvss_display = "  -"  # Два пробела для выравнивания
                else:
                    status = f"{RED}Не найдено{RESET}"
                    # Форматируем уровень
                    if severity == "Critical":
                        severity_display = f"{RED}{severity}{RESET}"
                    elif severity == "High":
                        severity_display = f"{YELLOW}{severity}{RESET}"
                    elif severity == "Medium":
                        severity_display = f"{BLUE}{severity}{RESET}"
                    else:
                        severity_display = severity
                    
                    # Форматируем CVSS score
                    if cvss_score is not None:
                        cvss_display = f"{cvss_score:.1f}".rjust(4)  # Выравнивание по правому краю (4 символа)
                    else:
                        cvss_display = "N/A".rjust(4)
                
                # Вывод строки с правильным выравниванием
                print(f"{index:<5} | {cve:<20} | {status:<{12 + len(RED) + len(RESET)}} | "
                      f"{severity_display:<{10 + len(RED) + len(YELLOW) + len(BLUE) + len(RESET)}} | "
                      f"{cvss_display:>6}")  # Выравнивание по правому краю для CVSS
                
    except Exception as e:
        print(f'\nОшибка: {str(e)}', file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()