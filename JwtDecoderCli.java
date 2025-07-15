import java.util.Base64;
import java.nio.charset.StandardCharsets;

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
            System.out.println(formatJson(payloadJson));

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

    private static String formatJson(String json) {
        StringBuilder result = new StringBuilder();
        int indentLevel = 0;
        boolean inQuotes = false;

        for (char c : json.toCharArray()) {
            if (c == '"' && (json.length() > 1 && json.charAt(json.indexOf(c) - 1) != '\\')) {
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