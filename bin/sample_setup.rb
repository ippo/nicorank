#!/usr/bin/env ruby
# coding: utf-8

code = 'voso'

dir = 'private'
Dir::mkdir dir unless Dir::exist? dir
dir = 'private/day'
Dir::mkdir dir unless Dir::exist? dir
dir = 'public/day'
Dir::mkdir dir unless Dir::exist? dir
dir = "public/day/#{code}"
Dir::mkdir dir unless Dir::exist? dir

yaml = <<EOS
---
:pass: voso
EOS
open("private/day/#{code}.yml", 'w').write yaml

yaml = <<EOS
---
:title: VOCALOID & something
:description: |-
  VOCALOID、UTAU、他音源の日刊ランキング。
  ポロリもあるよ。
:keywords:
- VOCALOID
- UTAU
- CeVIOカバー曲 or ささらオリジナル曲'
EOS
open("public/day/#{code}.yml", 'w').write yaml
