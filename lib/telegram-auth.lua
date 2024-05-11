local _M = {}
local ck = require "resty.cookie"
local template = require "resty.template"
local hmac = require "resty.hmac"
local resty_sha256 = require "resty.sha256"
local cjson = require "cjson"

local TELEGRAM_BOT_SHA_TOKEN = nil
local TELEGRAM_BOT_USERNAME = nil
local TELEGRAM_AUTH_URL = "/telegram-auth"
local TELEGRAM_AUTH_TEMPLATE = "auth.html"
local TELEGRAM_USER_IDS = {}
local COOKIE_NAME = "tg-auth-string"

local function removeKey(table, key)
    local element = table[key]
    table[key] = nil
    return element
end

function Set(list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

local function check_tg_data(args)
    local hash = removeKey(args, "hash")

    local check_string = ""
    local tkeys = {}
    local sorted_data = {}

    for k in pairs(args) do table.insert(tkeys, k) end
    table.sort(tkeys)

    for _, k in ipairs(tkeys) do
        table.insert(sorted_data, k .. "=" .. args[k])
    end

    check_string = table.concat(sorted_data, "\n")

    local hmac_sha256 = hmac:new(TELEGRAM_BOT_SHA_TOKEN, hmac.ALGOS.SHA256)

    if not hmac_sha256 then
        ngx.log(ngx.STDERR, "failed to create the hmac_sha256 object")
        return false
    end

    local check_hash = hmac_sha256:final(check_string, true)

    if not hmac_sha256:reset() then
        ngx.log(ngx.STDERR, "failed to reset hmac_sha256")
        return false
    end

    if check_hash == hash then
        local cookie, _ = ck:new()
        args["hash"] = hash
        local json = cjson.encode(args)

        cookie:set({
            key = COOKIE_NAME, value = json, path = "/",
        })
    end

    return check_hash == hash
end

local function check_cookie()
    local cookie, _ = ck:new()
    local json, _ = cookie:get(COOKIE_NAME)
    if not json then
        return false
    end

    local args = cjson.decode(json)
    local check_result = check_tg_data(args)
    if not check_result then
        return false
    end

    if not TELEGRAM_USER_IDS[args["id"]] then
        return false
    end

    return true
end


function _M.init(config)
    if config["bot_token"] then
        local sha256 = resty_sha256:new()
        sha256:update(config["bot_token"])
        TELEGRAM_BOT_SHA_TOKEN = sha256:final()
    end

    if config["bot_username"] then
        TELEGRAM_BOT_USERNAME = config["bot_username"]
    end

    if config["auth_url"] then
        TELEGRAM_AUTH_URL = config["auth_url"]
    end

    if config["auth_template"] then
        TELEGRAM_AUTH_TEMPLATE = config["auth_template"]
    end

    if config["user_ids"] then
        TELEGRAM_USER_IDS = Set(config["user_ids"])
    end

    if config["cookie_name"] then
        COOKIE_NAME = config["cookie_name"]
    end
end

function _M.check_auth()
    ngx.header["Cache-Control"] = "no-store"
    if not check_cookie() then
        ngx.redirect(TELEGRAM_AUTH_URL, 301)
    end
end

function _M.auth()
    ngx.header["Cache-Control"] = "no-store"
    local args, _ = ngx.req.get_uri_args()

    if args["hash"] then
        local check_result = check_tg_data(args)
        if not check_result then
            return ngx.exit(500)
        else
            return ngx.redirect("/", 301)
        end
    else
        if check_cookie() then
            return ngx.redirect("/", 301)
        end
        template.render(
            TELEGRAM_AUTH_TEMPLATE,
            {
                telgram_bot_username = TELEGRAM_BOT_USERNAME,
                callback_url = ngx.var.scheme .. "://" .. ngx.var.http_host .. ngx.var.request_uri,
            }
        )
    end
end

return _M
