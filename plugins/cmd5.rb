#!/usr/bin/env ruby
#
# Plugin cmd5
# Author L
#

plugin 'cmd5' do 
  web_server 'https://cmd5.com'
  supported_algorithm :md4, :md5, :md5_16, :sha1, :sha256, :sha512, :ntlm, :mysql3, :mysql

  # TODO 添加账号，支持Unix密码查询
  crack {
    r = get '/'
    unless r.body.empty?
      info = Hash[r.body.scan(/id="(.+?)" value="(.*?)"/)]
      data = {"__EVENTTARGET": info["__EVENTTARGET"],
              "__EVENTARGUMENT": info["__EVENTARGUMENT"],
              "__VIEWSTATE": info["__VIEWSTATE"],
              "__VIEWSTATEGENERATOR": info["__VIEWSTATEGENERATOR"],
              "ctl00$ContentPlaceHolder1$TextBoxInput": passwd,
              "ctl00$ContentPlaceHolder1$InputHashType": "md5",
              "ctl00$ContentPlaceHolder1$Button1": "\u67e5\u8be2",
              "ctl00$ContentPlaceHolder1$HiddenField1": "",
              "ctl00$ContentPlaceHolder1$HiddenField2": info["ctl00_ContentPlaceHolder1_HiddenField2"]}
      r = post('/', data, {'referer': web_server_url})

      text = r.body.force_encoding 'UTF-8'

      case text
      when /已查到,这是一条付费记录/
        raise Chargeable
      when /验证错误|请<a href=login.aspx/
        raise VerificationCodeError
      else
        #regexp = /id="ctl00_ContentPlaceHolder1_LabelAnswer">(.+?)<\/span>/
        regexp = /LabelAnswer" onmouseover="toggle\(\);">(.+?)<\/span>/
        text.extract(regexp)&.gsub(/<.*?>|。.*/, '') if text !~ /未查到/
      end
    end
  }
end
