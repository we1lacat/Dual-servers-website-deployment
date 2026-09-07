package site.we1l.common;

import lombok.Getter;
import org.springframework.http.HttpStatus;

/**
 * 业务异常：用于参数校验失败、资源不存在、鉴权失败等可预期错误。
 * 通过 code 推断 HTTP 状态码，方便 REST 层做 200/400/401/404/500 区分。
 */
@Getter
public class BusinessException extends RuntimeException {

    private final int code;

    public BusinessException(String message) {
        super(message);
        this.code = 400;
    }

    public BusinessException(int code, String message) {
        super(message);
        this.code = code;
    }

    /** 业务码 → HTTP 状态码 */
    public HttpStatus httpStatus() {
        if (code == 401) return HttpStatus.UNAUTHORIZED;
        if (code == 403) return HttpStatus.FORBIDDEN;
        if (code == 404) return HttpStatus.NOT_FOUND;
        if (code == 405) return HttpStatus.METHOD_NOT_ALLOWED;
        if (code == 409) return HttpStatus.CONFLICT;
        if (code == 429) return HttpStatus.TOO_MANY_REQUESTS;
        if (code == 400) return HttpStatus.BAD_REQUEST;
        if (code >= 500) return HttpStatus.INTERNAL_SERVER_ERROR;
        // 其他未识别的业务码走 200，前端按 code 字段判断
        return HttpStatus.OK;
    }
}
