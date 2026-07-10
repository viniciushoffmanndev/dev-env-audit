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
                    // Remove quebras de linha e espaços extras nas extremidades
                    cleanVersion = cleanVersion.replace(/[\r\n]+/g, ' ').trim();

                    // Regras cirúrgicas de Regex baseadas no rótulo (Case-Insensitive)
                    if (name.toLowerCase() === 'git') {
                        // Limpa "git version "
                        cleanVersion = cleanVersion.replace(/git\s+version\s+/i, '');
                    } 
                    else if (name.toLowerCase() === 'docker') {
                        // Limpa "Docker version " mas preserva o build
                        cleanVersion = cleanVersion.replace(/docker\s+version\s+/i, '');
                    } 
                    else if (name.toLowerCase() === 'wsl') {
                        // Remove "Versão do WSL:" ou caracteres corrompidos de encoding (VersÒo)
                        cleanVersion = cleanVersion.replace(/.*wsl[:\s]*/i, '');
                    } 
                    else if (name.toLowerCase() === 'python') {
                        // Limpa "Python "
                        cleanVersion = cleanVersion.replace(/python\s+/i, '');
                    } 
                    else if (name.toLowerCase() === 'pip') {
                        // Extrai estritamente "pip X.X" e depois descarta o caminho físico "from ..."
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
})();