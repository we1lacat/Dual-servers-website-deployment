package site.we1l.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 站点档案：站点名、简介、站主信息、备案号、联系邮箱。
 * 表中只保留 id = 1 的一行，作为全站配置。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("site_profile")
public class SiteProfile extends BaseEntity {

    @NotBlank(message = "站点名称不能为空")
    @Size(max = 64, message = "站点名称不能超过 64 个字符")
    private String siteName;

    @Size(max = 128, message = "站点简介不能超过 128 个字符")
    private String siteSlogan;

    @Size(max = 64, message = "站主名称不能超过 64 个字符")
    private String ownerName;

    private String ownerTitle;

    private String ownerAvatar;

    private String email;

    private String icpNo;

    private String icpUrl;

    private String footerNote;
}
