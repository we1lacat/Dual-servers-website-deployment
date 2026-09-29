package site.we1l.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 「服务」— 可下载的简历模板。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("resume_template")
public class ResumeTemplate extends BaseEntity {

    @NotBlank(message = "模板标题不能为空")
    private String title;

    /** PDF / DOCX */
    private String fileType;

    private String fileSize;

    private String fileUrl;

    private Integer sortOrder;

    private Integer status;
}
