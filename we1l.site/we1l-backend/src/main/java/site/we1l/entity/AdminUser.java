package site.we1l.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * 后台管理员账号。
 * password_hash 存 BCrypt 散列（如 $2a$10$....）。
 */
@Data
@TableName("admin_user")
public class AdminUser {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String username;
    private String passwordHash;
    private String displayName;
    private String role;
    private Integer status;
    private String lastLoginAt;
    private String createdAt;
    private String updatedAt;
}
