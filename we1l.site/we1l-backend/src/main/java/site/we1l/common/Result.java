package site.we1l.common;

import lombok.Data;

import java.io.Serializable;

/**
 * 统一 REST 响应包装。
 *
 * @param <T> 数据体类型
 */
@Data
public class Result<T> implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 业务码：0 成功，非 0 失败 */
    private int code;

    /** 提示信息 */
    private String message;

    /** 数据体 */
    private T data;

    public static <T> Result<T> ok() {
        return ok(null);
    }

    public static <T> Result<T> ok(T data) {
        Result<T> r = new Result<>();
        r.setCode(0);
        r.setMessage("success");
        r.setData(data);
        return r;
    }

    public static <T> Result<T> fail(String message) {
        return fail(500, message);
    }

    public static <T> Result<T> fail(int code, String message) {
        Result<T> r = new Result<>();
        r.setCode(code);
        r.setMessage(message);
        return r;
    }

    /** 别名：fail(int, String) 的同名形式，便于语义化调用 */
    public static <T> Result<T> error(int code, String message) {
        return fail(code, message);
    }
}
