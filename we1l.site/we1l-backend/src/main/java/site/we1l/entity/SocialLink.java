package site.we1l.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 「关于我」— 社交媒体矩阵。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("social_link")
public class SocialLink extends BaseEntity {

    @NotBlank(message = "平台名称不能为空")
    private String platform;

    private String handle;

    private String url;

    private String icon;

    private Integer sortOrder;

    private Integer status;
}
