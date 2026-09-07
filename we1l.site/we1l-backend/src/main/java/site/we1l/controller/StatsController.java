package site.we1l.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import site.we1l.common.Result;
import site.we1l.service.LearningItemService;
import site.we1l.service.NoteService;
import site.we1l.service.ResumeTemplateService;
import site.we1l.service.SkillService;
import site.we1l.service.SiteTrendService;
import site.we1l.service.SocialLinkService;
import site.we1l.service.WorkItemService;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 后台首页概览：各模块内容数量统计。
 */
@RestController
@RequestMapping("/api/admin/stats")
@RequiredArgsConstructor
public class StatsController {

    private final SiteTrendService siteTrendService;
    private final LearningItemService learningItemService;
    private final SkillService skillService;
    private final SocialLinkService socialLinkService;
    private final WorkItemService workItemService;
    private final NoteService noteService;
    private final ResumeTemplateService resumeTemplateService;

    @GetMapping
    public Result<Map<String, Object>> stats() {
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("trendCount", siteTrendService.count());
        data.put("learningCount", learningItemService.count());
        data.put("skillCount", skillService.count());
        data.put("socialCount", socialLinkService.count());
        data.put("workCount", workItemService.count());
        data.put("noteCount", noteService.count());
        data.put("resumeCount", resumeTemplateService.count());
        return Result.ok(data);
    }
}
