#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/runtime:6.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /code
COPY ["src/Ray.BiliBiliTool.Console/Ray.BiliBiliTool.Console.csproj", "src/Ray.BiliBiliTool.Console/"]
COPY ["src/Ray.BiliBiliTool.DomainService/Ray.BiliBiliTool.DomainService.csproj", "src/Ray.BiliBiliTool.DomainService/"]
COPY ["src/Ray.BiliBiliTool.Config/Ray.BiliBiliTool.Config.csproj", "src/Ray.BiliBiliTool.Config/"]
COPY ["src/Ray.BiliBiliTool.Infrastructure/Ray.BiliBiliTool.Infrastructure.csproj", "src/Ray.BiliBiliTool.Infrastructure/"]
COPY ["src/Ray.BiliBiliTool.Agent/Ray.BiliBiliTool.Agent.csproj", "src/Ray.BiliBiliTool.Agent/"]
COPY ["src/Ray.BiliBiliTool.Application/Ray.BiliBiliTool.Application.csproj", "src/Ray.BiliBiliTool.Application/"]
COPY ["src/Ray.BiliBiliTool.Application.Contracts/Ray.BiliBiliTool.Application.Contracts.csproj", "src/Ray.BiliBiliTool.Application.Contracts/"]
COPY ["src/Ray.Serilog.Sinks/Ray.Serilog.Sinks.CoolPushBatched/Ray.Serilog.Sinks.CoolPushBatched.csproj", "src/Ray.Serilog.Sinks/Ray.Serilog.Sinks.CoolPushBatched/"]
COPY ["src/Ray.Serilog.Sinks/Ray.Serilog.Sinks.Batched/Ray.Serilog.Sinks.Batched.csproj", "src/Ray.Serilog.Sinks/Ray.Serilog.Sinks.Batched/"]
COPY ["src/Ray.Serilog.Sinks/Ray.Serilog.Sinks.TelegramBatched/Ray.Serilog.Sinks.TelegramBatched.csproj", "src/Ray.Serilog.Sinks/Ray.Serilog.Sinks.TelegramBatched/"]
COPY ["src/Ray.Serilog.Sinks/Ray.Serilog.Sinks.WorkWeiXinBatched/Ray.Serilog.Sinks.WorkWeiXinBatched.csproj", "src/Ray.Serilog.Sinks/Ray.Serilog.Sinks.WorkWeiXinBatched/"]
COPY ["src/Ray.Serilog.Sinks/Ray.Serilog.Sinks.OtherApiBatched/Ray.Serilog.Sinks.OtherApiBatched.csproj", "src/Ray.Serilog.Sinks/Ray.Serilog.Sinks.OtherApiBatched/"]
COPY ["src/Ray.Serilog.Sinks/Ray.Serilog.Sinks.DingTalkBatched/Ray.Serilog.Sinks.DingTalkBatched.csproj", "src/Ray.Serilog.Sinks/Ray.Serilog.Sinks.DingTalkBatched/"]
COPY ["src/Ray.Serilog.Sinks/Ray.Serilog.Sinks.PushPlusBatched/Ray.Serilog.Sinks.PushPlusBatched.csproj", "src/Ray.Serilog.Sinks/Ray.Serilog.Sinks.PushPlusBatched/"]
COPY ["src/Ray.Serilog.Sinks/Ray.Serilog.Sinks.ServerChanBatched/Ray.Serilog.Sinks.ServerChanBatched.csproj", "src/Ray.Serilog.Sinks/Ray.Serilog.Sinks.ServerChanBatched/"]
COPY ["src/Ray.Serilog.Sinks/Ray.Serilog.Sinks.MicrosoftTeamsBatched/Ray.Serilog.Sinks.MicrosoftTeamsBatched.csproj", "src/Ray.Serilog.Sinks/Ray.Serilog.Sinks.MicrosoftTeamsBatched/"]
COPY ["src/Ray.Serilog.Sinks/Ray.Serilog.Sinks.WorkWeiXinAppBatched/Ray.Serilog.Sinks.WorkWeiXinAppBatched.csproj", "src/Ray.Serilog.Sinks/Ray.Serilog.Sinks.WorkWeiXinAppBatched/"]
COPY ["src/Ray.Serilog.Sinks/Ray.Serilog.Sinks.GotifyBatched/Ray.Serilog.Sinks.GotifyBatched.csproj", "src/Ray.Serilog.Sinks/Ray.Serilog.Sinks.GotifyBatched/"]
RUN dotnet restore "src/Ray.BiliBiliTool.Console/Ray.BiliBiliTool.Console.csproj"
COPY . .
WORKDIR "/code/src/Ray.BiliBiliTool.Console"
RUN dotnet build "Ray.BiliBiliTool.Console.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Ray.BiliBiliTool.Console.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
ENV TIME_ZONE=Asia/Shanghai
COPY --from=publish /app/publish .
COPY ./docker/scripts/* ./docker/crontab /app/scripts/
RUN ln -fs /usr/share/zoneinfo/$TIME_ZONE /etc/localtime \
    && echo $TIME_ZONE > /etc/timezone \
    && cp /etc/apt/sources.list /etc/apt/sources.list.bak \
#	&& sed -i 's/deb.debian.org/mirrors.163.com/g' /etc/apt/sources.list \
#	&& sed -i 's/security.debian.org/mirrors.163.com/g' /etc/apt/sources.list \
	&& apt-get clean \ 
    && apt-get update \
    && apt-get install -y cron tzdata tofrodos \
    && apt-get clean \ 
    && fromdos /app/scripts/entry_before.sh \
    && fromdos /app/scripts/entry.sh \
    && fromdos /app/scripts/entry_after.sh \
    && chmod -R +x /app/scripts/ \
    && fromdos /app/scripts/crontab
ENTRYPOINT ["/bin/bash", "-c", "/app/scripts/entry.sh"]
