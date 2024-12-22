clipboard="$(pbpaste)"

img_src=$(echo "$clipboard" | grep -o '<img[^>]*src="[^"]*"' | grep -o 'src="[^"]*"' | cut -d '"' -f 2)

# Копируем строку в буфер обмена
echo "$1" | pbcopy