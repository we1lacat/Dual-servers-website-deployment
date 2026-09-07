package site.we1l.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import site.we1l.common.Result;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.stream.Stream;

/**
 * 运维状态接口（前端右上角状态指示器数据源）：
 *
 * 判定规则：
 *  - monitor.up=false → level=danger  「无风控运行」（红）：A 机 Prometheus 经隧道不可达，
 *    或 node-b(10.10.0.1:9100) 抓取目标 down——监控中心失效，无任何风险感知。
 *  - monitor.up=true 且 backup.ok=false → level=warn 「风险运行中」（黄）：
 *    B 机本地备份目录超过 N 小时无新备份文件——数据存在丢失风险。
 *  - 全部正常 → level=ok 「站点正常」（绿）。
 *
 * 该接口仅返回聚合后的健康状态与轻量时间信息，不暴露内网拓扑细节。
 */
@RestController
@RequestMapping("/api/ops/status")
public class OpsStatusController {

    private static final DateTimeFormatter FMT =
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(2))
            .build();

    @Value("${we1l.ops.monitor-url:http://10.10.0.2:9090}")
    private String monitorUrl;

    @Value("${we1l.ops.backup-dir:/opt/we1l/backup}")
    private String backupDir;

    @Value("${we1l.ops.backup-max-age-hours:24}")
    private long backupMaxAgeHours;

    @GetMapping
    public Result<Map<String, Object>> status() {
        Map<String, Object> monitor = probeMonitor();
        Map<String, Object> backup = probeBackup();

        boolean monitorUp = Boolean.TRUE.equals(monitor.get("up"));
        boolean backupOk = Boolean.TRUE.equals(backup.get("ok"));

        String level;
        String label;
        if (!monitorUp) {
            level = "danger";
            label = "无风控运行";
        } else if (!backupOk) {
            level = "warn";
            label = "风险运行中";
        } else {
            level = "ok";
            label = "站点正常";
        }

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("level", level);
        data.put("label", label);
        data.put("monitor", monitor);
        data.put("backup", backup);
        return Result.ok(data);
    }

    /** 探测 A 机 Prometheus：查询 up 指标中 node-b 是否 = 1 */
    private Map<String, Object> probeMonitor() {
        Map<String, Object> result = new LinkedHashMap<>();
        try {
            HttpRequest req = HttpRequest.newBuilder()
                    .uri(URI.create(monitorUrl + "/api/v1/query?query=up"))
                    .timeout(Duration.ofSeconds(3))
                    .GET()
                    .build();
            HttpResponse<String> resp = httpClient.send(req, HttpResponse.BodyHandlers.ofString());
            if (resp.statusCode() != 200) {
                result.put("up", false);
                result.put("detail", "prometheus http " + resp.statusCode());
                return result;
            }
            JsonNode root = objectMapper.readTree(resp.body());
            JsonNode arr = root.path("data").path("result");
            boolean nodeBUp = false;
            int nodeBCount = 0;
            for (JsonNode item : arr) {
                JsonNode metric = item.path("metric");
                String job = metric.path("job").asText("");
                String value = item.path("value").size() > 1
                        ? item.path("value").get(1).asText("") : "";
                if ("node-b".equals(job)) {
                    nodeBCount++;
                    if ("1".equals(value)) {
                        nodeBUp = true;
                    }
                }
            }
            result.put("up", nodeBUp && nodeBCount > 0);
            result.put("detail", "node-b targets=" + nodeBCount);
        } catch (IOException | InterruptedException e) {
            result.put("up", false);
            result.put("detail", "unreachable: " + e.getClass().getSimpleName());
        }
        return result;
    }

    /** 探测 B 机本地备份目录：最新 we1l-*.db 距今是否 ≤ 阈值 */
    private Map<String, Object> probeBackup() {
        Map<String, Object> result = new LinkedHashMap<>();
        Path dir = Path.of(backupDir);
        try (Stream<Path> files = Files.list(dir)) {
            Instant newest = files
                    .filter(p -> p.getFileName().toString().matches("we1l-\\d{8}-\\d{4}\\.db"))
                    .map(p -> {
                        try {
                            return Files.getLastModifiedTime(p).toInstant();
                        } catch (IOException e) {
                            return Instant.EPOCH;
                        }
                    })
                    .max(Comparator.naturalOrder())
                    .orElse(null);
            if (newest == null) {
                result.put("ok", false);
                result.put("detail", "no backup file found");
                return result;
            }
            long ageHours = Duration.between(newest, Instant.now()).toHours();
            result.put("ok", ageHours <= backupMaxAgeHours);
            result.put("lastTime", FMT.format(LocalDateTime.ofInstant(newest, ZoneId.of("Asia/Shanghai"))));
            result.put("ageHours", ageHours);
        } catch (IOException e) {
            result.put("ok", false);
            result.put("detail", "dir unreadable: " + e.getClass().getSimpleName());
        }
        return result;
    }
}
