import java.util.Base64;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.text.SimpleDateFormat;
import java.util.TimeZone;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class JwtDecoderCli {

    public static void main(String[] args) {
        if (args.length == 0) {
            System.err.println("Ошибка: Укажите JWT-токен как аргумент командной строки");
            System.err.println("Пример: java JwtDecoderCli \"eyJhbGciOi...\"");
            System.exit(1);
        }

        String jwtToken = args[0];
        System.out.println("Исходный токен: " + jwtToken + "\n");

        try {
            String[] parts = jwtToken.split("\\.");
            if (parts.length != 3) {
                throw new IllegalArgumentException("Неверный формат JWT");
            }

            String headerJson = decodeBase64Url(parts[0]);
            String payloadJson = decodeBase64Url(parts[1]);

            System.out.println("=== Header (Заголовок) ===");
            System.out.println(formatJson(headerJson) + "\n");

            System.out.println("=== Payload (Данные) ===");
            String formattedPayload = formatJsonWithTimestamps(payloadJson);
            System.out.println(formattedPayload);

        } catch (Exception e) {
            System.err.println("Ошибка декодирования: " + e.getMessage());
            System.exit(1);
        }
    }

    private static String decodeBase64Url(String base64Url) {
        String base64 = base64Url.replace('-', '+').replace('_', '/');
        switch (base64.length() % 4) {
            case 2: base64 += "=="; break;
            case 3: base64 += "="; break;
        }
        byte[] decodedBytes = Base64.getDecoder().decode(base64);
        return new String(decodedBytes, StandardCharsets.UTF_8);
    }

    private static String formatJsonWithTimestamps(String json) {
        // Сначала преобразуем временные метки
        String jsonWithTimestamps = convertTimestampsToHumanReadable(json);
        
        // Затем форматируем как JSON (оригинальный метод)
        return formatJson(jsonWithTimestamps);
    }

    private static String convertTimestampsToHumanReadable(String json) {
        // Паттерн для поиска полей "exp" и "iat" с числовыми значениями
        Pattern pattern = Pattern.compile("\"(exp|iat)\":\\s*(\\d+)");
        Matcher matcher = pattern.matcher(json);
        
        StringBuffer result = new StringBuffer();
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH-mm-ss z");
        sdf.setTimeZone(TimeZone.getTimeZone("UTC"));
        
        while (matcher.find()) {
            String fieldName = matcher.group(1);
            long timestamp = Long.parseLong(matcher.group(2)) * 1000; // Convert to milliseconds
            Date date = new Date(timestamp);
            String humanReadable = sdf.format(date);
            
            // Добавляем комментарий с человеко-читаемым временем
            String replacement = String.format("\"%s\": %d, // %s", 
                fieldName, Long.parseLong(matcher.group(2)), humanReadable);
            matcher.appendReplacement(result, replacement);
        }
        matcher.appendTail(result);
        
        return result.toString();
    }

    private static String formatJson(String json) {
        StringBuilder result = new StringBuilder();
        int indentLevel = 0;
        boolean inQuotes = false;

        for (char c : json.toCharArray()) {
            if (c == '"' && (result.length() == 0 || result.charAt(result.length() - 1) != '\\')) {
                inQuotes = !inQuotes;
            }

            if (!inQuotes) {
                switch (c) {
                    case '{':
                    case '[':
                        result.append(c).append("\n").append(getIndent(++indentLevel));
                        break;
                    case '}':
                    case ']':
                        result.append("\n").append(getIndent(--indentLevel)).append(c);
                        break;
                    case ',':
                        result.append(c).append("\n").append(getIndent(indentLevel));
                        break;
                    case ':':
                        result.append(": ");
                        break;
                    default:
                        result.append(c);
                }
            } else {
                result.append(c);
            }
        }

        return result.toString();
    }

    private static String getIndent(int level) {
        StringBuilder indent = new StringBuilder();
        for (int i = 0; i < level; i++) {
            indent.append("    "); // 4 пробела на уровень
        }
        return indent.toString();
    }
}