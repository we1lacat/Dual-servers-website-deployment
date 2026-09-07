package site.we1l.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 「笔记 / 服务」— 学习笔记。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("note")
public class Note extends BaseEntity {

    @NotBlank(message = "笔记标题不能为空")
    private String title;

    private String category;

    private String summary;

    /** 正文（纯文本或 Markdown） */
    private String content;

    private String cover;

    private String author;

    private Integer views;

    /** 展示用发布时间，如 2026-08 */
    private String publishedAt;

    private Integer status;
}
