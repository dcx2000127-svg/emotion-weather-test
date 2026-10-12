# 情绪天气预报测评

静态前端由 GitHub Pages 托管；密码验证和每个密码 3 次的完成次数由 Supabase Postgres RPC 原子校验。无需 Supabase service-role key 放到浏览器。

## 配置

1. 在 Supabase 创建项目，在 SQL Editor 运行 `supabase/schema.sql`。
2. 在 schema.sql 最后复制 INSERT 示例，换成至少 8 位的唯一密码后运行。不要把真实密码提交到公开仓库。
3. 在 Supabase 项目的 API 设置页复制 Project URL 和 anon/public key，将它们填入 `index.html` 顶部脚本的 `SUPABASE_URL`、`SUPABASE_ANON_KEY`。
4. 创建 GitHub 仓库，把本目录全部文件推送到仓库的 `main` 分支。
5. 在仓库 Settings → Pages 中将 Source 设为 **GitHub Actions**。工作流会自动发布，完成后 Pages 页面会显示访问地址。

## 使用与限制

- 仅完成整份测评后扣除一次；数据库更新是原子操作，并发情况下也不会超过次数上限。
- 结果分享链接使用 URL hash 携带分数和类型，不写入数据库。收到链接的人可以直接查看分享结果。
- 分享链接和静态网页需要通过公开地址访问；本地 `file://` 地址不能分享给其他人。
- `anon/public key` 会出现在浏览器，这是 Supabase 前端的正常用法。数据库表不开放客户端读取，调用仅限两个校验 RPC。绝不要把 `service_role` key 放入网站。
- 邀请密码应使用不易猜测的随机字符串。公开网站的密码入口是访问控制，不是用户身份认证；这套实现没有按 IP 限速。
- 结果页面不保存个人身份信息。测评次数只由 Supabase 数据库保存。
- 需要批量生成更多兑换码时，在 SQL Editor 运行 `supabase/issue_codes.sql` 一次，然后执行 `select * from public.issue_test_codes(10);`。每个新码可完成 3 次，明文只在结果中显示一次，数据库只存哈希。
