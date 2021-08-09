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

RUN groupadd -r mass && useradd -r -m -g mass mass && usermod -a -G users,mass mass

COPY --from=builder /etc/localtime /etc
COPY --from=builder /etc/timezone /etc
COPY --from=builder /opt/ /opt/

ENV PATH=$PATH:/opt/miner:/opt/wallet

RUN apt-get -qq update \
    && apt-get -qq install -y --no-install-recommends ca-certificates curl gosu tini expect tcl jq zsh git \
    && git clone git://github.com/robbyrussell/oh-my-zsh.git /root/.oh-my-zsh \
    && git clone git://github.com/zsh-users/zsh-autosuggestions /root/.oh-my-zsh/plugins/zsh-autosuggestions \
    && cp /root/.oh-my-zsh/templates/zshrc.zsh-template /root/.zshrc \
    && sed -i "s/robbyrussell/ys/g" /root/.zshrc \
    && sed -i "s/plugins=(git)/plugins=(git z zsh-autosuggestions)/g" /root/.zshrc \
    && sed -i "1i DISABLE_AUTO_UPDATE=\"true\"" ~/.zshrc \
    && cd /opt/wallet/conf \
    && mv sample-config.min.json ../config.json \
    && mv walletcli-config.json ../ \
    && cd /opt/miner/conf \
    && mv sample-config.m2.json ../config.json \
    && cd /opt/ \
    && ls -al /opt/

WORKDIR /opt/wallet
