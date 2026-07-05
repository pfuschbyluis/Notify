-- ============================================================
-- bootstrap.lua – Cleanup, Start-Diagnose
-- ============================================================
-- Diese Datei läuft absichtlich zuletzt: sie fasst nur Handler
-- zusammen, die auf ALLE anderen Module zugreifen dürfen.

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    JobOutfit.CloseAllNui()

    local s = JobOutfit.State
    if s.isWearingJobOutfit and s.savedCivilianSkin then
        JobOutfit.Clothing.RestoreCivilian()
    end

    JobOutfit.Peds.DeleteAll()
end)

-- Diagnose beim Start nur bei aktivem Debug (Config.Debug).
CreateThread(function()
    if not JobOutfit.IsDebug() then return end
    JobOutfit.Debug(('Client geladen. GetCurrentResourceName() = "%s"'):format(GetCurrentResourceName()), 'BOOT')
    JobOutfit.Debug('NUI-Callbacks registriert: close, selectOutfit, restoreClothes, admin:save, admin:close, admin:getPosition, admin:outfits:*', 'BOOT')
end)

-- Test-Callback zum Prüfen der JS->Lua-Brücke (nur bei aktivem Debug).
RegisterNUICallback('debug:ping', function(_, cb)
    JobOutfit.Debug('debug:ping empfangen! JS->Lua fetch FUNKTIONIERT.', 'NUI')
    cb('pong')
end)
