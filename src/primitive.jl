using SerialPorts	
using Logging

"""
	send(device, :A, fr=frequency=10000, duty=50)

:Aコマンドは，全体の周波数とduty比を設定する．
```
:A -> キャリア周波数設定
  - frequency : キャリア周波数 1000 - 24000
  - duty : キャリアONデューティー 0 - 100
```
"""
function send(device::Stimulator, sym, ::Val{:A}
				;fr=10000, frequency::Int=fr
				,duty::Int=50)
	#* validity check
	@assert 1000 ≤ frequency ≤ 24000 "the value of frequency is out of range (1000 - 24000)" 
	@assert    0 ≤   duty    ≤   100 "the value of duty is out of range (0 - 100)"
	#=5桁固定=# frequency = lpad(frequency, 5, "0") 
	#=3桁固定=# 	  duty = lpad(duty, 3, "0")
	send(device, "A,$frequency,$duty,")
end

"""
    send(device, :B, channel       = 0 (=ch),
                     voltage       = 30 (=V), 
                     potentiometer = 10 (=P), 
                     frequency     = 100 (=fr), 
                     duty = 50,
                     type = 0,
                     step = 1)

:Bコマンドは4チャンネルの内の1つの詳細を変更する．
```
:B -> 各チャンネル設定 
  - channel : 設定チャンネル 0, 1, 2, 3
  - voltage : 電圧値 30, 60, 90
  - potentiometer : ポテンショメータ 0 - 127
  - frequency : バースト周波数 0 - 400
  - duty : バーストONデューティー 0～100
  - type : 波形タイプ 0：方形, 1：正弦, 2：三角
  - step : 波形可変ステップ 1, 2, 4, 5
```
"""
function send(device::Stimulator, sym, ::Val{:B}
				;ch=0, channel::Int=ch
				,V=30, voltage::Int=V
				,P=0,  potentiometer::Int=P
				,fr=100, frequency::Int=fr
				,duty::Int=50
				,type::Int=0
				,step::Int=1)
	#* validity check
	@assert channel in 0:3           "the value of channel must be 0 - 3"
	@assert voltage in (30, 60, 90)  "the value of voltage must be 30, 60 or 90"
	@assert 0 ≤ potentiometer ≤ 100  "the value of potentiometer is out of range (0-100)"
	@assert 0 ≤   frequency   ≤ 400  "the value of frequency is out of range (0-400)" 
	@assert 0 ≤     duty      ≤ 100  "the value of duty is out of range (0-100)"
	@assert type in (0, 1, 2)        "the value of type must be 0 (rectangle), 1 (sin), 2 (triangle)"
	@assert step in (1,2,4,5)        "the value of step must be 1, 2, 4 or 5"
	#=3桁固定=# potentiometer = lpad(potentiometer, 3, "0")
	#=3桁固定=# 	 frequency = lpad(frequency, 3, "0")
	#=3桁固定=# 	 		duty = lpad(duty, 3, "0")
	send(device, "B,$channel,$voltage,$potentiometer,$frequency,$duty,$type,$step,")
end

"""
    send(device, :C, channels = [0,7,...,0] (=CHs),
                     on_off   = [0,1,...,0] )

:Cコマンドは25ある電極ポートの ON/OFF と 各チャンネルの接続関係を規定する．
```
:C -> 刺激信号個別選択 
  - channels : 各ポートに接続するチャンネルのベクトル 
  		ex [0, 1, ... (25 port 分)] (各0 - 7の整数)
  - on_off : 各ポートの On/Off 
  		ex [true, false, ... (25 port 分)] (true(1) / false(0))
```
"""
function send(device::Stimulator, sym, ::Val{:C}
				;CHs=fill(0,25),channels=CHs
				,on_off=fill(false,25))
	#* validity check
	@assert length(channels)==25 "the channels must have 25 elements (each value is 0 - 7)"
	@assert length(on_off)==25 "the channels must have 25 elements (each value is true/1 or false/0)"
	@assert all(ch-> ch ∈ 0:7 && isinteger(ch), channels) "the each value of channels(CHs) must be 0 - 7"
	@assert all(ch-> ch ∈ (0,1) && isinteger(ch), on_off) "the each  value of on_off must be true/1 or false/0"
	channels = string.(channels)
	on_off = [o==1 ? "on_" : "off" for o in on_off]
	send(device, "C,$(join(permutedims([channels on_off]),",")),")
end

"""
:Eコマンドは刺激装置からの出力を受け取る．
"""
function send(device::Stimulator, sym, ::Val{:E})
	send(device, :E, false)
end

send(device, sym; karg...) = send(device, sym, Val(Symbol(sym)); karg...)	

"""
    send(device, no_arg_command)

`no_arg_command` are supported following Symbols
```
:F -> EEPROM設定書き込み
:G -> EEPROM設定読み出し
:H -> デフォルト設定
:K -> バッチ処理開始
:L -> バッチ処理停止
:Z -> パワーオンリセット
```
"""
function send(device::Stimulator, command, other)
	command = "\x02$command\x03"
	try
		write(device.serial, command)
		@info "success to send :" command
	catch e
		@error "failure to send :" command
		rethrow(e)
	end
end