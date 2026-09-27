package site.we1l.controller;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import site.we1l.common.BusinessException;
import site.we1l.common.Result;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

/**
 * 通用图片上传（后台专用）。
 *
 * 路由在 /api/admin/** 下，受 SecurityConfig 的 JWT 保护；
 * 落盘目录由 we1l.upload.dir 决定，再由 WebConfig 以 /uploads/** 静态暴露。
 * 前端拿到的是可直接渲染的相对 URL（如 /uploads/20260927102030_ab12cd34.png）。
 */
@Slf4j
@RestController
@RequestMapping("/api/admin")
public class UploadController {

    /** 允许的图片扩展名（与 Content-Type 双重校验） */
    private static final Set<String> ALLOWED_EXT = Set.of("jpg", "jpeg", "png", "gif", "webp", "bmp");

    private static final DateTimeFormatter TS = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");

    private final Path uploadDir;
    private final String urlPrefix;

    public UploadController(@Value("${we1l.upload.dir}") String uploadDir,
                            @Value("${we1l.upload.url-prefix:/uploads}") String urlPrefix) {
        this.uploadDir = Paths.get(uploadDir).toAbsolutePath().normalize();
        this.urlPrefix = urlPrefix.endsWith("/")
                ? urlPrefix.substring(0, urlPrefix.length() - 1)
                : urlPrefix;
    }

    /**
     * 上传单张图片。
     * 表单字段名固定为 file；返回 /uploads/xxx 形式的 URL。
     */
    @PostMapping("/upload")
    public Result<String> upload(@RequestParam("file") MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BusinessException(400, "上传文件为空");
        }

        String contentType = file.getContentType();
        if (contentType == null || !contentType.toLowerCase(Locale.ROOT).startsWith("image/")) {
            throw new BusinessException(400, "仅支持图片文件");
        }

        String ext = extOf(file.getOriginalFilename());
        if (!ALLOWED_EXT.contains(ext)) {
            throw new BusinessException(400, "不支持的图片格式：" + (ext.isEmpty() ? "(未知)" : ext));
        }

        String name = LocalDateTime.now().format(TS)
                + "_" + UUID.randomUUID().toString().substring(0, 8)
                + "." + ext;

        try {
            Files.createDirectories(uploadDir);
            Path target = uploadDir.resolve(name).normalize();
            // 防目录穿越：解析后必须仍在 uploadDir 之内
            if (!target.startsWith(uploadDir)) {
                throw new BusinessException(400, "非法文件名");
            }
            file.transferTo(target);
        } catch (IOException e) {
            log.error("图片上传失败", e);
            throw new BusinessException(500, "图片保存失败");
        }

        String url = urlPrefix + "/" + name;
        log.info("图片上传成功：{} -> {}", file.getOriginalFilename(), url);
        return Result.ok(url);
    }

    private String extOf(String filename) {
        if (filename == null) {
            return "";
        }
        int i = filename.lastIndexOf('.');
        return i < 0 ? "" : filename.substring(i + 1).toLowerCase(Locale.ROOT);
    }
}
