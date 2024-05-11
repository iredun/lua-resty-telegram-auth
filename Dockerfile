FROM openresty/openresty:buster

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -y --no-install-recommends openresty-opm
RUN opm get flex-runtime/lua-resty-cookie
RUN opm get bungle/lua-resty-template
RUN opm get jkeys089/lua-resty-hmac