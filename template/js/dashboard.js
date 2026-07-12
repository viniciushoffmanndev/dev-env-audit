/**
 * DevEnv Audit - Dashboard Logic
 * Process raw JSON payloads injected by the compiler pipeline.
 */

(function () {
    // 1. Renderização de Telemetria de Armazenamento
    if (typeof storageData !== 'undefined' && storageData.Drives) {
        const storageContainer = document.getElementById('storage-container');
        if (storageContainer) {
            const drives = Array.isArray(storageData.Drives) ? storageData.Drives : [storageData.Drives];
            
            drives.forEach(drive => {
                const isCritical = drive.UsagePercentage >= 85;
                const barColor = isCritical ? 'bg-red-500 animate-pulse' : 'bg-cyan-500';
                const bgBadge = isCritical ? 'bg-red-500/10 text-red-400 border-red-500/20' : 'bg-slate-700/50 text-slate-300 border-slate-600/50';
                const badgeText = isCritical ? 'STORAGE CRISIS' : 'HEALTHY';

                const driveHtml = `
                    <div class="bg-slate-900/50 p-4 rounded-lg border border-slate-700/60 flex flex-col justify-between">
                        <div>
                            <div class="flex justify-between items-center mb-2">
                                <span class="text-base font-bold text-slate-200">Drive ${drive.Letter} (${drive.FileSystem})</span>
                                <span class="px-2 py-0.5 rounded text-[10px] font-semibold border ${bgBadge}">${badgeText}</span>
                            </div>
                            <p class="text-xs text-slate-400 mb-4 font-mono">${drive.VolumeName || 'Local Disk'}</p>
                            
                            <div class="w-full bg-slate-700 rounded-full h-3 overflow-hidden mb-2">
                                <div class="${barColor} h-3 rounded-full transition-all duration-500" style="width: ${drive.UsagePercentage}%"></div>
                            </div>
                        </div>
                        
                        <div class="flex justify-between text-xs font-mono mt-2 pt-2 border-t border-slate-800">
                            <div><span class="text-slate-500">Used:</span> <span class="text-slate-300">${Number(drive.Used_GB).toFixed(2)} GB</span></div>
                            <div><span class="text-slate-500">Free:</span> <span class="text-slate-300">${Number(drive.Free_GB).toFixed(2)} GB</span></div>
                            <div><span class="text-slate-500">Usage:</span> <span class="${isCritical ? 'text-red-400 font-bold' : 'text-slate-300'}">${drive.UsagePercentage}%</span></div>
                        </div>
                    </div>
                `;
                storageContainer.innerHTML += driveHtml;
            });
        }
    }

    // 2. Renderização do Ecossistema de Desenvolvimento (Módulo 04)
    if (typeof devData !== 'undefined') {
        function renderDevItems(dataBlock, containerId) {
            const container = document.getElementById(containerId);
            if (!dataBlock || !container) return;

            Object.entries(dataBlock).forEach(([name, version]) => {
                const isInstalled = version !== "Not Installed";
                const badgeClass = isInstalled 
                    ? "bg-amber-500/10 text-amber-400 border-amber-500/20 font-mono" 
                    : "bg-slate-700/30 text-slate-500 border-slate-800/80";
                
                let cleanVersion = version;

                if (isInstalled) {
                    cleanVersion = cleanVersion.replace(/[\r\n]+/g, ' ').trim();

                    if (name.toLowerCase() === 'git') {
                        cleanVersion = cleanVersion.replace(/git\s+version\s+/i, '');
                    } 
                    else if (name.toLowerCase() === 'docker') {
                        cleanVersion = cleanVersion.replace(/docker\s+version\s+/i, '');
                    } 
                    else if (name.toLowerCase() === 'wsl') {
                        cleanVersion = cleanVersion.replace(/.*wsl[:\s]*/i, '');
                    } 
                    else if (name.toLowerCase() === 'python') {
                        cleanVersion = cleanVersion.replace(/python\s+/i, '');
                    } 
                    else if (name.toLowerCase() === 'pip') {
                        const match = cleanVersion.match(/pip\s+([^\s]+)/i);
                        cleanVersion = match ? match[1] : cleanVersion.split(' ')[0];
                    }
                } else {
                    cleanVersion = "Missing";
                }

                const rowHtml = `
                    <div class="flex justify-between items-center py-1 border-b border-slate-800/40 last:border-0">
                        <span class="text-slate-300 font-medium">${name}</span>
                        <span class="px-2 py-0.5 rounded text-xs border ${badgeClass}" title="${version}">${cleanVersion}</span>
                    </div>
                `;
                container.innerHTML += rowHtml;
            });
        }
        renderDevItems(devData.Tools, 'dev-tools-container');
        renderDevItems(devData.Runtimes, 'dev-runtimes-container');
    }

    // 3. Renderização de Telemetria de Rede & Conectividade (Módulo 06)
    if (typeof networkData !== 'undefined' && networkData.Addressing) {
        const adapterContainer = document.getElementById('network-adapters-container');
        
        if (adapterContainer && networkData.Addressing.Interfaces) {
            const interfaces = Array.isArray(networkData.Addressing.Interfaces) 
                ? networkData.Addressing.Interfaces 
                : [networkData.Addressing.Interfaces];
                
            interfaces.forEach(net => {
                const nameLower = net.InterfaceName.toLowerCase();
                const isVirtual = nameLower.includes('vethernet') || 
                                  nameLower.includes('wsl') || 
                                  nameLower.includes('docker') ||
                                  nameLower.includes('loopback');
                
                const badgeStyle = isVirtual 
                    ? "bg-purple-500/10 text-purple-400 border-purple-500/20" 
                    : "bg-cyan-500/10 text-cyan-400 border-cyan-500/20";

                const rowHtml = `
                    <div class="flex justify-between items-center py-1 border-b border-slate-800/40 last:border-0">
                        <span class="text-slate-300 font-medium max-w-[160px] truncate" title="${net.InterfaceName}">${net.InterfaceName}</span>
                        <span class="px-2 py-0.5 rounded text-[11px] border ${badgeStyle}">${net.IPAddress}</span>
                    </div>
                `;
                adapterContainer.innerHTML += rowHtml;
            });
        }

        // Preenche as informações básicas de endereçamento
        document.getElementById('net-gateway').textContent = networkData.Addressing.Gateway || 'N/A';
        document.getElementById('net-public').textContent = networkData.Addressing.PublicIP || 'Offline';

        // Preenche e formata os dados de latência
        const formatPing = (val) => typeof val === 'number' ? `${val}ms` : val;
        
        document.getElementById('ping-gw').textContent = `GW: ${formatPing(networkData.Latency_ms.Gateway)}`;
        document.getElementById('ping-google').textContent = `Goo: ${formatPing(networkData.Latency_ms.Google)}`;
        document.getElementById('ping-cf').textContent = `CF: ${formatPing(networkData.Latency_ms.Cloudflare)}`;
    }
    
// 4. Renderização do Módulo de Placas de Vídeo (Módulo 07 - GPU)
    if (typeof gpuData !== 'undefined' && gpuData.VideoCards) {
        const gpuContainer = document.getElementById('gpu-container');
        
        if (gpuContainer) {
            const cards = Array.isArray(gpuData.VideoCards) ? gpuData.VideoCards : [gpuData.VideoCards];
            
            cards.forEach(card => {
                const isNvidia = card.Name.toLowerCase().includes('nvidia');
                
                // Atribuição de cores semântica baseada na marca da GPU
                const brandBadge = isNvidia 
                    ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' 
                    : 'bg-blue-500/10 text-blue-400 border-blue-500/20';
                
                const formattedVRAM = typeof card.VRAM_GB === 'number' 
                    ? `${card.VRAM_GB} GB` 
                    : card.VRAM_GB;

                const cardHtml = `
                    <div class="bg-slate-900/40 p-3 rounded-lg border border-slate-700/40 flex flex-col justify-between text-xs">
                        <div class="flex justify-between items-start mb-2">
                            <span class="text-slate-200 font-bold font-sans truncate max-w-[220px]" title="${card.Name}">${card.Name}</span>
                            <span class="px-1.5 py-0.5 rounded font-mono text-[10px] border ${brandBadge}">${formattedVRAM}</span>
                        </div>
                        <div class="flex justify-between items-center font-mono text-slate-400 mt-1">
                            <span>Driver: <span class="text-slate-300 text-[11px]">${card.DriverVersion}</span></span>
                            <span class="${card.Status === 'OK' ? 'text-emerald-400 font-bold' : 'text-amber-400'}">${card.Status}</span>
                        </div>
                    </div>
                `;
                gpuContainer.innerHTML += cardHtml;
            });
        }
    }
})();