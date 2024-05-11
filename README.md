# lua-resty-telegram-auth

lua-resty-telegram-auth is a module to close access to any locations by [Telegram Login Widget](https://core.telegram.org/widgets/login)

## Disclaimer

This module is a beta version and written just for fun for trying to use new technology. Use it in production, to your own risk.

## Synopsis

```nginx
worker_processes  1;

events {
  worker_connections 1024;
}

http {
    init_by_lua_block {
        require "telegram-auth".init({
            bot_token = "<BOT TOKEN>",
            bot_username = "<BOT USERNAME WITHOUT @>",
            user_ids = {"1", "2", "3"}
        })
    }
  
    server {
        listen 80;
        charset utf-8;

        location / {
            default_type text/html;
            access_by_lua_block {
                local tg = require "telegram-auth"
                tg.check_auth()
            }

            content_by_lua_block {
                ngx.say("sensetive data")
            }
        }

        location /telegram-auth {
            default_type text/html;
            content_by_lua_block {
                local tg = require "telegram-auth"
                tg.auth()
            }
        }
    }
} 
```

# Table of Contents

* [Installation](#installation)
  * [Using OpenResty Package Manager (opm)](#using-openresty-package-manager-opm)
  * [Using Nginx Lua Module](#using-nginx-lua-module)
* [Configuration](#configuration)
  * [Auth template context](#auth-template-context)
* [For developers](#for-developers)

# Installation

## Using OpenResty Package Manager (opm)

```bash
❯ opm get iredun/lua-resty-telegram-auth
```

OPM repository for `lua-resty-telegram-auth` is located at <https://opm.openresty.org/package/iredun/lua-resty-telegram-auth/>.

## Using Nginx Lua Module

Firstly, check and install all dependencies:

* [flex-runtime/lua-resty-cookie](https://github.com/twilio/lua-resty-cookie)
* [bungle/lua-resty-template](https://github.com/bungle/lua-resty-template)
* [jkeys089/lua-resty-hmac](https://github.com/jkeys089/lua-resty-hmac)

Set search paths for pure Lua external libraries (';;' is the default path) in `nginx.conf`:

`lua_package_path '/foo/bar/?.lua;/blah/?.lua;/path-to-module/lua-resty-telegram-auth/?.lua;;';`

# Configuration

Here is an example:

```lua
init_by_lua_block {
    require "telegram-auth".init({
        bot_token = "<BOT TOKEN>",
        bot_username = "<BOT USERNAME WITHOUT @>",
        user_ids = {"1", "2", "3"}
    })
}
```

Here are the possible configuration options:

| Option          | Default          | Description                                     |
| --------------- | ---------------- | ----------------------------------------------- |
| `bot_token`     | `nil`            | Yours Telegram bot token                        |
| `bot_username`  | `nil`            | Yours Telegram bot username without @           |
| `auth_url`      | `/telegram-auth` | Location to redirect user for showing auth page |
| `auth_template` | `auth.html`      | Path to template to rendering auth page        |
| `user_ids`      | `{}`             | List of user IDs who can get access              |
| `cookie_name`   | `tg-auth-string` | Name of cookie to store TG data                 |

## Auth template context

In the template, you can access to variables:

* `telgram_bot_username`
* `callback_url` - current url `auth_url`

Default template you can find in `html/auth.html`

## Cookie

In cookies you can get json with user information:

```json
{
  "last_name": "Smith",
  "id": "11111",
  "photo_url": "<url>",
  "auth_date": "1715359637",
  "hash": "hash for check user data",
  "username": "jsmith",
  "first_name": "John"
}
```

## For developers

You can start base example in Docker, just change init settings in `nginx/default.conf` and run

```bash
docker-compose up -d
```
