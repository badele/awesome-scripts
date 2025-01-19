Here’s the translated text in English with added links to **isync** and
**mblaze**:

---

# Maildir Email Size Analyzer

## Preface

I needed to clean up my Gmail inbox. However, Gmail doesn’t provide tools to
identify the senders who consume the most disk space.

To address this, I used the excellent tools
[isync](https://isync.sourceforge.io/) and
[mblaze](https://git.vuxu.org/mblaze/about/) to pinpoint the senders consuming
the most space in my mailbox.

## Prerequisites

`nix shell nixpkgs#isync nixpkgs#mblaze nixpkgs#python312Packages.termgraph`

## Example Usage

```bash
./analyze "$HOME/.mail/perso/[Gmail]/All Mail"
./size_by_sender
```

```text
valentine.tanguy@fake.mail                 : ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 1.62 B
leo.briere@fake.mail                       : ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 706.63M
titouan.cornet@fake.mail                   : ▇▇▇▇▇▇▇▇▇▇▇▇▇ 437.38M
ismaël.adam@fake.mail                      : ▇▇▇▇▇▇▇▇▇▇ 329.93M
axel.vincent@fake.mail                     : ▇▇▇▇▇▇▇ 253.87M
charlie.larue@fake.mail                    : ▇▇▇▇▇▇▇ 253.65M
eliott.morin@fake.mail                     : ▇▇▇ 128.89M
titouan.lebel@fake.mail                    : ▇▇▇ 128.62M
nino.rey@fake.mail                         : ▇▇ 84.24M
mael.grandjean@fake.mail                   : ▇ 57.02M
rose.chevallier@fake.mail                  : ▇ 49.99M
léna.marcel@fake.mail                      : ▇ 49.40M
lyam.schaeffer@fake.mail                   : ▇ 46.12M
antonin.levy@fake.mail                     : ▇ 45.97M
zoé.yildiz@fake.mail                       : ▇ 44.08M
théo.jeanne@fake.mail                      : ▇ 43.80M
lenny.langlet@fake.mail                    : ▇ 35.81M
nino.beau@fake.mail                        : ▇ 35.71M
mathis.leray@fake.mail                     : ▏ 27.08M
louka.jan@fake.mail                        : ▏ 25.68M
clara.carrier@fake.mail                    : ▏ 25.08M
```

```bash
./emails_for_sender "valentine.tanguy@fake.mail"
```

```text
2025-01-12   valentine.tanguy@fake.mail  33M   Track cycling 
2025-01-12   valentine.tanguy@fake.mail  32M   Lunch meeting
2019-10-05   valentine.tanguy@fake.mail  32M   Photos 1
2020-09-19   valentine.tanguy@fake.mail  28M   Video 23
2025-01-12   valentine.tanguy@fake.mail  26M   All on bikes
2025-01-12   valentine.tanguy@fake.mail  25M   King's Trail / Geneva
2019-07-28   valentine.tanguy@fake.mail  24M   Photos leo
2025-01-12   valentine.tanguy@fake.mail  23M   Wasp sting
2017-12-25   valentine.tanguy@fake.mail  22M   Drawing software...
2016-08-22   valentine.tanguy@fake.mail  22M   Document supply
```

Now, all that's left is to go to Gmail and search for all emails from a specific
person by looking for subjects or the sender using `from:<email_address>`

## Miscellaneous

- [Firstname generator](https://lorraine-hipseau.me/)
