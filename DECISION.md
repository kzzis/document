# デプロイ方針(決定事項)

このプロジェクトのデプロイ構成に関する方針をまとめたものです。今後別の選択肢を検討したくなったとき、まずここに立ち返ってください。

## 結論

**IISを使わない。wwwroot統合構成の ASP.NET Core(Kestrel)を、Windowsサービスとして単体で動かす。**

```
Windows Server
├── IIS ── 既存 Classic ASP アプリ(そのまま。触らない)
└── Kestrel(TodoApi) ── ポート8080を直接リッスン
      React のビルド成果物(wwwroot)と API を同一プロセスで配信
      sc.exe で Windows サービス化(Gitea と同じ方式)
```

- フロントエンドとバックエンドは**統合**(wwwrootに混ぜ込む)
- Webサーバーは**IISを使わない**(Kestrel単体)
- サービス化は**sc.exe**(Giteaで実績のある方式)

## 決定に至った経緯

検討の過程で、いくつかの軸が出てきました。それぞれの結論だけ記録しておきます。

### 1. フロント/バックを統合するか、分離するか → 統合

| 選択肢 | 判断 |
| --- | --- |
| wwwrootに統合 | ○ 採用。デプロイが1系統で済み、CORSも不要になる |
| リバースプロキシ(ARR/nginx)で分離を維持 | 見送り。将来のクラウド移行(Azure)先が「まだ候補」の段階で、確度の低い将来に備えて学習コストを払う理由がないと判断 |

理由の核心:**wwwroot統合 → 将来分離する場合の後戻りコストは、API呼び出し部分など数ファイルの変更で半日程度。** 逆に先に分離用のリバースプロキシを学習・構築すると、統合が本命になった時点(Azure App Serviceが候補に挙がった時点)でその投資が丸ごと無駄になる。非対称なので、今困らない方(統合)を選ぶ。

### 2. Webサーバーを IIS にするか、使わないか → 使わない

| 選択肢 | 判断 |
| --- | --- |
| IIS(別サイト・別アプリプールで既存と分離) | 見送り。技術的には問題ないが、既存Classic ASPとの競合防止(サイト・プール・パス・ポート・権限を全部分ける)の手間と確認作業が煩雑 |
| IISなし(Kestrel単体 + Windowsサービス化) | ○ 採用。既存アプリに一切触れずに済む。GiteaのNSSMではない`sc.exe`によるサービス化の実績があり、同じパターンを踏襲できる |

理由の核心:**既存Classic ASPへの影響をゼロにしたい**という要求が最終的に決め手になった。IISでの分離は「ちゃんとやれば安全」だが「ちゃんとやる」ための確認項目が多く、面倒さがリスクに見合わない規模感だった。

### 3. 将来のインフラ移行への備え → 今は備えない

| 検討した移行先 | 想定される作業 |
| --- | --- |
| オンプレ Windows Server 継続 | 今のままで問題なし |
| VPS / Linux 移行 | Kestrel単体構成なのでLinux移行時は `sc.exe` → `systemd`、`UseWindowsService()` → `UseSystemd()` に差し替えるだけ。nginxへの置き換えも比較的軽い |
| クラウド(EC2等、VM貸し) | VPS移行とほぼ同じ |
| クラウド(Azure App Service) | **wwwroot統合構成がほぼそのまま乗る**。むしろ相性が良い |

いずれの移行先も「まだ候補の一つ」で確度が低い段階のため、事前の作り込みはしない。移行が具体化した時点で、該当する変更を行う。

## 実装への反映

### Program.cs

```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Host.UseWindowsService();   // Windowsサービスとして起動できるようにする

builder.Services.AddControllers();
builder.Services.AddDbContext<AppDbContext>(opt =>
    opt.UseNpgsql(builder.Configuration.GetConnectionString("Default")));

builder.Services.AddScoped<ITodoRepository, TodoRepository>();
builder.Services.AddScoped<ITodoService, TodoService>();

// 開発時のみ Vite dev server(5173)からのアクセスを許可
builder.Services.AddCors(o => o.AddPolicy("dev", p => p
    .WithOrigins("http://localhost:5173")
    .AllowAnyHeader()
    .AllowAnyMethod()));

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseCors("dev");
}

app.UseDefaultFiles();
app.UseStaticFiles();
app.MapControllers();
app.MapFallbackToFile("index.html");

app.Run();
```

### appsettings.json

```json
{
  "Urls": "http://0.0.0.0:8080"
}
```

### .csproj

```xml
<ItemGroup>
  <PackageReference Include="Microsoft.Extensions.Hosting.WindowsServices" Version="8.0.0" />
</ItemGroup>
```

### デプロイ(サービス登録は初回のみ)

```powershell
# 発行
dotnet publish TodoApi -c Release -o C:\deploy\TodoApi

# 初回のみ:サービス登録
sc.exe create TodoApiService binPath= "C:\deploy\TodoApi\TodoApi.exe" start= auto
sc.exe failure TodoApiService reset= 86400 actions= restart/60000/restart/60000/restart/60000

# ファイアウォール(初回のみ)
New-NetFirewallRule -DisplayName "TodoApi" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow

# 起動・更新時
sc.exe stop TodoApiService
robocopy C:\deploy\todo-publish C:\deploy\TodoApi /MIR
sc.exe start TodoApiService
```

## この方針を見直すべきタイミング

以下のいずれかが具体化したら、この文書に立ち返って再検討する。

- **Azure移行が正式決定した** → wwwroot統合構成のままApp Serviceへ。IIS/sc.exe関連の記述は丸ごと不要になる
- **VPS/Linux移行が正式決定した** → `UseWindowsService()` → `UseSystemd()`、`sc.exe` → systemdユニットに置き換え。nginx導入も合わせて検討
- **同一サーバーで動かす社内システムが増え、Kestrelの直接ポート運用が管理しづらくなった** → IISまたはnginxでのリバースプロキシ集約を再検討
- **外部(社外)公開の要件が出てきた** → HTTPS化(社内CAではなく正式な証明書)とセキュリティ要件を別途検討
