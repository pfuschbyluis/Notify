-- ============================================================
-- database.lua – Tabellen anlegen, Caches
-- ============================================================

local NS = JobOutfitServer

local function EnsureTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `multijob_outfit_jobs` (
            `job_name` VARCHAR(50) NOT NULL,
            `enabled` TINYINT(1) NOT NULL DEFAULT 1,
            PRIMARY KEY (`job_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `multijob_outfit_peds` (
            `job_name` VARCHAR(50) NOT NULL,
            `enabled` TINYINT(1) NOT NULL DEFAULT 1,
            `model` VARCHAR(100) NOT NULL DEFAULT '',
            `coord_x` FLOAT NOT NULL DEFAULT 0,
            `coord_y` FLOAT NOT NULL DEFAULT 0,
            `coord_z` FLOAT NOT NULL DEFAULT 0,
            `heading` FLOAT NOT NULL DEFAULT 0,
            `scenario` VARCHAR(100) NOT NULL DEFAULT '',
            `label` VARCHAR(150) NOT NULL DEFAULT '[E] Outfit-Menü öffnen',
            PRIMARY KEY (`job_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `multijob_outfit_outfits` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `job_name` VARCHAR(50) NOT NULL,
            `grade` INT NOT NULL DEFAULT 0,
            `label` VARCHAR(150) NOT NULL DEFAULT '',
            `sort_order` INT NOT NULL DEFAULT 0,
            `male_clothes` LONGTEXT NULL,
            `female_clothes` LONGTEXT NULL,
            PRIMARY KEY (`id`),
            KEY `idx_job_grade` (`job_name`, `grade`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
end

function NS.ReloadJobsCache()
    local rows = MySQL.query.await('SELECT job_name, enabled FROM `multijob_outfit_jobs`') or {}
    local out = {}
    for _, row in ipairs(rows) do
        out[row.job_name] = NS.FromDBBool(row.enabled)
    end
    NS.Cache.Jobs = out
end

function NS.ReloadPedsCache()
    local rows = MySQL.query.await('SELECT * FROM `multijob_outfit_peds`') or {}
    local out = {}
    for _, row in ipairs(rows) do
        out[row.job_name] = {
            enabled = NS.FromDBBool(row.enabled),
            model = row.model,
            coords = { x = row.coord_x, y = row.coord_y, z = row.coord_z, w = row.heading },
            scenario = row.scenario or '',
            label = row.label or '[E] Outfit-Menü öffnen'
        }
    end
    NS.Cache.Peds = out
end

function NS.ReloadOutfitsCache()
    local rows = MySQL.query.await('SELECT * FROM `multijob_outfit_outfits` ORDER BY job_name, grade, sort_order, id') or {}
    local out = {}

    for _, row in ipairs(rows) do
        out[row.job_name] = out[row.job_name] or {}
        out[row.job_name][row.grade] = out[row.job_name][row.grade] or {}

        local okMale, male = pcall(json.decode, row.male_clothes or '{}')
        local okFemale, female = pcall(json.decode, row.female_clothes or '{}')

        table.insert(out[row.job_name][row.grade], {
            id = row.id,
            label = row.label,
            male = (okMale and type(male) == 'table') and male or {},
            female = (okFemale and type(female) == 'table') and female or {}
        })
    end

    NS.Cache.Outfits = out
end

-- Lädt die "echten" Jobs aus der ESX-Datenbanktabelle `jobs`. Dient als
-- Whitelist: im Admin-Panel lassen sich nur Jobs anlegen, die es wirklich
-- gibt – keine frei erfundenen Job-Namen mehr.
function NS.ReloadValidJobs()
    local out = {}
    local ok, rows = pcall(function()
        return MySQL.query.await('SELECT `name`, `label` FROM `jobs`')
    end)

    if ok and type(rows) == 'table' then
        for _, row in ipairs(rows) do
            if NS.IsSafeJobKey(row.name) then
                out[row.name] = row.label or row.name
            end
        end
    else
        print('[job_outfit] ESX-`jobs`-Tabelle nicht lesbar – Job-Beschränkung inaktiv (alle bekannten Jobs bleiben nutzbar).')
    end

    NS.Cache.ValidJobs = out
end

-- true, wenn eine echte Jobliste geladen werden konnte. Nur dann wird
-- eingeschränkt; ohne Liste (z.B. andere DB-Struktur) bleibt alles nutzbar.
function NS.HasValidJobList()
    return NS.Cache.ValidJobs ~= nil and next(NS.Cache.ValidJobs) ~= nil
end

function NS.IsRealJob(jobName)
    if not NS.HasValidJobList() then return true end
    return NS.Cache.ValidJobs[jobName] ~= nil
end

function NS.ReloadAllCaches()
    NS.ReloadValidJobs()
    NS.ReloadJobsCache()
    NS.ReloadPedsCache()
    NS.ReloadOutfitsCache()
end

function NS.JobHasUsableOutfits(jobName)
    local grades = NS.Cache.Outfits[jobName]
    if type(grades) ~= 'table' then return false end

    for _, outfits in pairs(grades) do
        for _, outfit in ipairs(outfits) do
            if (outfit.male and next(outfit.male)) or (outfit.female and next(outfit.female)) then
                return true
            end
        end
    end

    return false
end

NS.DbReady = false

CreateThread(function()
    EnsureTables()
    NS.ReloadAllCaches()

    Config.AllowedJobs = NS.Cache.Jobs
    Config.JobPeds = NS.Cache.Peds

    NS.DbReady = true
    print('[job_outfit] Datenbank gelesen: Jobs/Peds/Outfits bereit (kein Schreibzugriff beim Restart).')
end)
