package site.we1l.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.MediaType;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

/**
 * 401 入口点：Filter 链路直接回调，将 401 + JSON body 写出。
 * 单独定义 Bean 是为了确保 Spring Security 能正确注入到 ExceptionTranslationFilter 中
 * （lambda 在某些版本下会被解析为不同对象，导致 NPE）。
 */
@Component
public class JsonAuthenticationEntryPoint implements AuthenticationEntryPoint {

    private final ObjectMapper json = new ObjectMapper();

    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response,
                         AuthenticationException authException) throws java.io.IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        // 用 HashMap 而非 Map.of：Map.of 不支持 value 为 null，
        // data=null 时会抛 NPE，导致 500 而非 401。
        Map<String, Object> body = new HashMap<>();
        body.put("code", 401);
        body.put("message", "未登录或登录已过期");
        body.put("data", null);
        response.getWriter().write(json.writeValueAsString(body));
    }
}
