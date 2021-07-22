FROM alpine:3.12 as builder

ARG MINERVER=v2.0.1
ARG WALLETVER=v2.0.1
ENV PATH=$PATH:/opt
ENV TZ=Asia/Shanghai

RUN apk --no-cache add bash tzdata \
 && mkdir -p /tmp/linux /opt/miner /opt/wallet \
 && wget -q --no-check-certificate https://github.com/massnetorg/MassNet-miner/releases/download/${MINERVER}/massminer-linux-amd64.tgz -O /tmp/mass-miner.tgz && tar -zxvf /tmp/mass-miner.tgz -C /tmp/linux --strip-components=1  \
 && mv /tmp/linux/* /opt/miner \
 && wget -q --no-check-certificate https://github.com/massnetorg/MassNet-wallet/releases/download/${WALLETVER}/masswallet-linux-amd64.tgz -O /tmp/mass-wallet.tgz && tar -zxvf /tmp/mass-wallet.tgz -C /tmp/linux --strip-components=1  \
 && mv /tmp/linux/* /opt/wallet \
 && cp /usr/share/zoneinfo/$TZ /etc/localtime \
 && echo $TZ > /etc/timezone \
 && cat /etc/timezone \
 && rm -rf /tmp/* \
 && apk del tzdata

FROM ubuntu:20.04

RUN groupadd -r chia && useradd -r -m -g chia chia && usermod -a -G users,chia chia

ENV PATH=$PATH:/opt
WORKDIR /opt

COPY --from=builder /etc/localtime /etc
COPY --from=builder /etc/timezone /etc
COPY --from=builder /opt/* /opt

RUN apt-get -qq update \
    && apt-get -qq install -y --no-install-recommends ca-certificates curl gosu tini \
    && cd /opt/ \
    && ls -al /opt/
