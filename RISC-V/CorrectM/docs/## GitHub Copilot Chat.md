## GitHub Copilot Chat

- Extension: 0.37.9 (prod)
- VS Code: 1.109.3 (b6a47e94e326b5c209d118cf0f994d6065585705)
- OS: linux 6.17.0-19-generic x64
- GitHub Account: Pratham-Bit-Flip

## Network

User Settings:
```json
  "http.systemCertificatesNode": true,
  "github.copilot.advanced.debug.useElectronFetcher": true,
  "github.copilot.advanced.debug.useNodeFetcher": false,
  "github.copilot.advanced.debug.useNodeFetchFetcher": true
```

Connecting to https://api.github.com:
- DNS ipv4 Lookup: Error (2 ms): getaddrinfo EAI_AGAIN api.github.com
- DNS ipv6 Lookup: Error (1 ms): getaddrinfo EAI_AGAIN api.github.com
- Proxy URL: None (2 ms)
- Electron fetch (configured): Error (4 ms): Error: net::ERR_INTERNET_DISCONNECTED
	at SimpleURLLoaderWrapper.<anonymous> (node:electron/js2c/utility_init:2:10684)
	at SimpleURLLoaderWrapper.emit (node:events:519:28)
  [object Object]
  {"is_request_error":true,"network_process_crashed":false}
- Node.js https: Error (21 ms): Error: getaddrinfo EAI_AGAIN api.github.com
	at GetAddrInfoReqWrap.onlookupall [as oncomplete] (node:dns:122:26)
- Node.js fetch: Error (30 ms): TypeError: fetch failed
	at node:internal/deps/undici/undici:14900:13
	at process.processTicksAndRejections (node:internal/process/task_queues:105:5)
	at async n._fetch (/home/prathamesh-desai/.vscode/extensions/github.copilot-chat-0.37.9/dist/extension.js:4862:26129)
	at async n.fetch (/home/prathamesh-desai/.vscode/extensions/github.copilot-chat-0.37.9/dist/extension.js:4862:25777)
	at async u (/home/prathamesh-desai/.vscode/extensions/github.copilot-chat-0.37.9/dist/extension.js:4894:190)
	at async CA.h (file:///usr/share/code/resources/app/out/vs/workbench/api/node/extensionHostProcess.js:116:41743)
  Error: getaddrinfo EAI_AGAIN api.github.com
  	at GetAddrInfoReqWrap.onlookupall [as oncomplete] (node:dns:122:26)

Connecting to https://api.githubcopilot.com/_ping:
- DNS ipv4 Lookup: Error (1 ms): getaddrinfo EAI_AGAIN api.githubcopilot.com
- DNS ipv6 Lookup: Error (1 ms): getaddrinfo EAI_AGAIN api.githubcopilot.com
- Proxy URL: None (37 ms)
- Electron fetch (configured): Error (3 ms): Error: net::ERR_INTERNET_DISCONNECTED
	at SimpleURLLoaderWrapper.<anonymous> (node:electron/js2c/utility_init:2:10684)
	at SimpleURLLoaderWrapper.emit (node:events:519:28)
  [object Object]
  {"is_request_error":true,"network_process_crashed":false}
- Node.js https: Error (21 ms): Error: getaddrinfo EAI_AGAIN api.githubcopilot.com
	at GetAddrInfoReqWrap.onlookupall [as oncomplete] (node:dns:122:26)
- Node.js fetch: Error (27 ms): TypeError: fetch failed
	at node:internal/deps/undici/undici:14900:13
	at process.processTicksAndRejections (node:internal/process/task_queues:105:5)
	at async n._fetch (/home/prathamesh-desai/.vscode/extensions/github.copilot-chat-0.37.9/dist/extension.js:4862:26129)
	at async n.fetch (/home/prathamesh-desai/.vscode/extensions/github.copilot-chat-0.37.9/dist/extension.js:4862:25777)
	at async u (/home/prathamesh-desai/.vscode/extensions/github.copilot-chat-0.37.9/dist/extension.js:4894:190)
	at async CA.h (file:///usr/share/code/resources/app/out/vs/workbench/api/node/extensionHostProcess.js:116:41743)
  Error: getaddrinfo EAI_AGAIN api.githubcopilot.com
  	at GetAddrInfoReqWrap.onlookupall [as oncomplete] (node:dns:122:26)

Connecting to https://copilot-proxy.githubusercontent.com/_ping:
- DNS ipv4 Lookup: Error (1 ms): getaddrinfo EAI_AGAIN copilot-proxy.githubusercontent.com
- DNS ipv6 Lookup: Error (1 ms): getaddrinfo EAI_AGAIN copilot-proxy.githubusercontent.com
- Proxy URL: None (2 ms)
- Electron fetch (configured): Error (3 ms): Error: net::ERR_INTERNET_DISCONNECTED
	at SimpleURLLoaderWrapper.<anonymous> (node:electron/js2c/utility_init:2:10684)
	at SimpleURLLoaderWrapper.emit (node:events:519:28)
  [object Object]
  {"is_request_error":true,"network_process_crashed":false}
- Node.js https: Error (24 ms): Error: getaddrinfo EAI_AGAIN copilot-proxy.githubusercontent.com
	at GetAddrInfoReqWrap.onlookupall [as oncomplete] (node:dns:122:26)
- Node.js fetch: Error (31 ms): TypeError: fetch failed
	at node:internal/deps/undici/undici:14900:13
	at process.processTicksAndRejections (node:internal/process/task_queues:105:5)
	at async n._fetch (/home/prathamesh-desai/.vscode/extensions/github.copilot-chat-0.37.9/dist/extension.js:4862:26129)
	at async n.fetch (/home/prathamesh-desai/.vscode/extensions/github.copilot-chat-0.37.9/dist/extension.js:4862:25777)
	at async u (/home/prathamesh-desai/.vscode/extensions/github.copilot-chat-0.37.9/dist/extension.js:4894:190)
	at async CA.h (file:///usr/share/code/resources/app/out/vs/workbench/api/node/extensionHostProcess.js:116:41743)
  Error: getaddrinfo EAI_AGAIN copilot-proxy.githubusercontent.com
  	at GetAddrInfoReqWrap.onlookupall [as oncomplete] (node:dns:122:26)

Connecting to https://mobile.events.data.microsoft.com: Error (3 ms): Error: net::ERR_INTERNET_DISCONNECTED
	at SimpleURLLoaderWrapper.<anonymous> (node:electron/js2c/utility_init:2:10684)
	at SimpleURLLoaderWrapper.emit (node:events:519:28)
  [object Object]
  {"is_request_error":true,"network_process_crashed":false}
Connecting to https://dc.services.visualstudio.com: Error (3 ms): Error: net::ERR_INTERNET_DISCONNECTED
	at SimpleURLLoaderWrapper.<anonymous> (node:electron/js2c/utility_init:2:10684)
	at SimpleURLLoaderWrapper.emit (node:events:519:28)
  [object Object]
  {"is_request_error":true,"network_process_crashed":false}
Connecting to https://copilot-telemetry.githubusercontent.com/_ping: Error (20 ms): Error: getaddrinfo EAI_AGAIN copilot-telemetry.githubusercontent.com
	at GetAddrInfoReqWrap.onlookupall [as oncomplete] (node:dns:122:26)
Connecting to https://copilot-telemetry.githubusercontent.com/_ping: Error (19 ms): Error: getaddrinfo EAI_AGAIN copilot-telemetry.githubusercontent.com
	at GetAddrInfoReqWrap.onlookupall [as oncomplete] (node:dns:122:26)
Connecting to https://default.exp-tas.com: Error (19 ms): Error: getaddrinfo EAI_AGAIN default.exp-tas.com
	at GetAddrInfoReqWrap.onlookupall [as oncomplete] (node:dns:122:26)

Number of system certificates: 435

## Documentation

In corporate networks: [Troubleshooting firewall settings for GitHub Copilot](https://docs.github.com/en/copilot/troubleshooting-github-copilot/troubleshooting-firewall-settings-for-github-copilot).