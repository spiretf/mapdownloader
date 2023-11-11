#pragma semicolon 1
#include <sourcemod>
#include <cURL>
#include <tf2>

public Plugin:myinfo =
{
	name = "map downloader",
	author = "Icewind",
	description = "Automatically download missing maps",
	version = "0.2",
	url = "https://spire.tf"
};

new CURL_Default_opt[][2] = {
	{_:CURLOPT_NOSIGNAL,1},
	{_:CURLOPT_NOPROGRESS,1},
	{_:CURLOPT_TIMEOUT,300},
	{_:CURLOPT_CONNECTTIMEOUT,120},
	{_:CURLOPT_USE_SSL,CURLUSESSL_TRY},
	{_:CURLOPT_SSL_VERIFYPEER,0},
	{_:CURLOPT_SSL_VERIFYHOST,0},
	{_:CURLOPT_VERBOSE,0}
};

#define CURL_DEFAULT_OPT(%1) curl_easy_setopt_int_array(%1, CURL_Default_opt, sizeof(CURL_Default_opt))

new Handle:g_hCvarUrl = INVALID_HANDLE;

public OnPluginStart() {
	g_hCvarUrl = CreateConVar("sm_map_download_base", "https://fastdl.serveme.tf/maps", "map download url", FCVAR_PROTECTED);

	RegServerCmd("changelevel", HandleChangeLevelAction);
}

public Action:HandleChangeLevelAction(args) {
	new String:part[128];
	new String:arg[128];
	int argpos = 0;

	for (int i = 1; i <= args; i++) {
		GetCmdArg(i, part, sizeof(part));
		strcopy(arg[argpos], sizeof(arg) - argpos, part);
		argpos += strlen(part);
	}

	if (arg[strlen(arg) - 1] == ':') {
		PrintToChatAll("Invalid input, to input urls, replace '://' with ':/'");
		return Plugin_Handled;
	}

	PrintToServer("Changing to: %s", arg);

	if (StrContains(arg, ":/") > 0) {
		ChangeLevelUrl(arg);
		return Plugin_Handled;
	}

	decl String:path[128];
	Format(path, sizeof(path), "maps/%s.bsp", arg);

	if (FileExists(path)) {
		return Plugin_Continue;
	} else {
		PrintToChatAll("Map %s not found, trying to download", path);
		DownloadMap(arg, path);
		return Plugin_Handled;
	}
}

public ChangeLevelUrl(String:url[128]) {
	decl String:path[128];
	decl String:mapFull[128];
	decl String:map[128];
	decl String:fullUrl[512];
	strcopy(fullUrl, sizeof(fullUrl), url);

	// allow http:/foo as alias for http://foo to work around source messing with the arguments
	if (StrContains(fullUrl, "://") == -1) {
		ReplaceString(fullUrl, sizeof(fullUrl), ":/", "://");
	}

	int index = FindCharInString(fullUrl, '/', true);
	if (index == -1) {
		PrintToServer("Invalid url: %s", fullUrl);
		return;
	}
	strcopy(mapFull, sizeof(mapFull), url[index]);

	if (FindCharInString(mapFull, '.') > 0) {
		SplitString(mapFull, ".", map, sizeof(map));
	}

	Format(path, sizeof(path), "maps/%s.bsp", map);

	PrintToServer("Saving %s to %s", fullUrl, path);

	DownloadMapUrl(map, fullUrl, path);
}

public DownloadMap(String:map[128], String:targetPath[128]) {
	decl String:fullUrl[512];
	decl String:BaseUrl[128];
	GetConVarString(g_hCvarUrl, BaseUrl, sizeof(BaseUrl));
	Format(fullUrl, sizeof(fullUrl), "%s/%s.bsp", BaseUrl, map);
	DownloadMapUrl(map, fullUrl, targetPath);
}

public DownloadMapUrl(String:map[128], String:fullUrl[512], String:targetPath[128]) {
	new Handle:curl = curl_easy_init();
	new Handle:output_file = curl_OpenFile(targetPath, "wb");
	CURL_DEFAULT_OPT(curl);

	PrintToChatAll("Trying to download %s from %s", map, fullUrl);

	new Handle:hDLPack = CreateDataPack();
	WritePackCell(hDLPack, _:output_file);
	WritePackString(hDLPack, map);
	WritePackString(hDLPack, targetPath);

	curl_easy_setopt_handle(curl, CURLOPT_WRITEDATA, output_file);
	curl_easy_setopt_string(curl, CURLOPT_URL, fullUrl);
	curl_easy_perform_thread(curl, onComplete, hDLPack);
}

public onComplete(Handle:hndl, CURLcode:code, any hDLPack) {
	decl String:map[128];
	decl String:targetPath[128];

	ResetPack(hDLPack);
	CloseHandle(Handle:ReadPackCell(hDLPack)); // output_file
	ReadPackString(hDLPack, map, sizeof(map));
	ReadPackString(hDLPack, targetPath, sizeof(targetPath));
	CloseHandle(hDLPack);
	CloseHandle(hndl);

	if (code != CURLE_OK) {
		PrintToChatAll("Error downloading map %s", map);
		decl String:sError[256];
		curl_easy_strerror(code, sError, sizeof(sError));
		PrintToChatAll("cURL error: %s", sError);
		PrintToChatAll("cURL error code: %d", code);
		DeleteFile(targetPath);
	} else {
		//PrintToChatAll("map size(%s): %d", targetPath, FileSize(targetPath));
		if (FileSize(targetPath) < 1024) {
			PrintToChatAll("Map file to small, discarding");
			DeleteFile(targetPath);
			return;
		}
		PrintToChatAll("Successfully downloaded map %s", map);
		changeLevel(map);
	}
	return;
}

public changeLevel(String:map[128]) {
	decl String:command[512];
	Format(command, sizeof(command), "changelevel %s", map);
	ServerCommand(command, sizeof(command));
}
