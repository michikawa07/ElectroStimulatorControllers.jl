#: ####################################################
#: 安全のための補助関数
#: ####################################################

export reset_saftyvoltage, reset_saftytime, increase_saftyvoltage, increase_saftytime

const _safty_voltage = Ref{Int}(15)
function increase_saftyvoltage(val::Int) 
	_safty_voltage[] = val
	@warn "Now maximum voltate is $(_safty_voltage[]) [V]"
end
reset_saftyvoltage() = increase_saftyvoltage(15)

const _safty_time = Ref{Int}(10)
function increase_saftytime(val::Int) 
	_safty_time[] = val
	@warn "Now maximum stimulus time is $(_safty_time[]) [s]"
end
reset_saftytime() = increase_saftytime(10) 

#: ####################################################
#: Wrapper method を使うための struct
#: ####################################################

export _ch, _p

struct Channel; num end
Base.:*(n::Int, ::Type{Channel}) = Channel(n)
Base.:(:)( x::Channel, y::Channel ) = [Channel(n) for n in (x.num):(y.num)]

struct Port; num end
Base.:*(n::Int, ::Type{Port}) = Port(n)
Base.:(:)( x::Port, y::Port ) = [Port(n) for n in (x.num):(y.num)]

const _ch, _p = Channel, Port

#: ####################################################
#: Wrapper method
#: ####################################################

#= Aコマンド =# export setcarrier, setcarrierfrequency, setcarrierduty 
#= Bコマンド =# export setburstduty, setburstfreqency, setvolatge, setwavetype, setwavestep	
#= Cコマンド =# export switchON, switchOFF, setconnections, resetconnections
#= Eコマンド =# export readdevice 

#* Aコマンドのラッパー
"""
	setcarrierfrequency(dev::Stimulator, frequency)

デバイスのキャリア周波数を設定する．\\
範囲は `1000 - 24000`
"""
setcarrierfrequency(dev,  frequency) = begin
	send(dev, :A; frequency, duty=dev.status[:carrier_duty])
	dev.status[:carrier_frequency] = frequency
	dev.status
end

"""
	setcarrierduty(dev::Stimulator, duty)

デバイスのキャリアduty比を設定する．\\
範囲は `0 - 100`
"""
setcarrierduty(dev,  duty) = begin
	send(dev, :A; duty, fr=dev.status[:carrier_frequency])
	dev.status[:carrier_duty] = duty
	dev.status
end

"""
setcarrier(dev::Stimulator, frequency, duty)

デバイスのキャリア周波数とキャリアduty比を設定する．\\
`frequency`の範囲は `1000 - 24000`\\
`duty`の範囲は `0 - 100`
"""
setcarrier(dev, frequency, duty) = begin
	send(dev, :A; duty, frequency)
	dev.status[:carrier_frequency] = frequency
	dev.status[:carrier_duty] = duty
	dev.status
end

#* Bコマンドのラッパー
"""
	setburstduty(dev::Stimulator, channel::Channel, duty)	
	setburstduty(dev::Stimulator, [ch1_duty, ch2_duty, ch3_duty, ch4_duty])	

channel で指定した電極チャンネルのバーストduty [%] を設定する.
配列でまとめてdutyを与えることもできる.

#Example

```
# ch1 のバーストduty比を10%に変更
setburstduty(dev, 1_ch, 10)

# ch1-4 のバーストduty比を全て30%に変更
setburstduty(dev, 1_ch, [30, 30, 30, 30])
```
"""
setburstduty(dev, channel::Channel, duty) = begin
	@assert channel ∈ (1_ch:4_ch) "The value of channel must be 1_ch ~ 4_ch"
	ch = channel.num
	V, P = dev.status[:voltage][ch]
	fr = dev.status[:burst_frequency][ch]
	send( dev, :B; ch, V, P, fr, duty, type=0, step=1 )
	dev.status[:burst_duty][ch] = duty
	dev.status
end

"""
	setburstfreqency(dev::Stimulator, channel::Channel, frequency)	
	setburstfreqency(dev::Stimulator, [ch1_fr, ch2_fr, ch3_fr, ch4_fr])	

channel で指定した電極チャンネルのバースト周波数 [Hz] を設定する.
配列でまとめてfrequencyを与えることもできる.

#Example

```
# ch1 のバースト周波数を150Hzに変更
setburstfreqency(dev, 1_ch, 150)

# ch1-4 のバースト周波数を全て100Hzに変更
setburstfreqency(dev, 1_ch, [100, 100, 100, 100])
```
"""
setburstfreqency(dev, channel::Channel, fr) = begin
	@assert channel ∈ (1_ch:4_ch) "The value of channel must be 1_ch ~ 4_ch"
	ch = channel.num
	V, P = dev.status[:voltage][ch]
	duty = dev.status[:burst_duty][ch]
	send( dev, :B; ch, V, P, fr, duty, type=0, step=1 )
	dev.status[:burst_frequency][ch] = fr
	dev.status
end

setwavetype() = begin
	
end

setwavestep() = begin
	
end

"""
	setburstfreqency(dev::Stimulator, channel::Channel, voltage)
	setburstfreqency(dev::Stimulator, [ch1_vol, ch2_vol, ch3_vol, ch4_vol])	

channel で指定した電極チャンネルの電圧値 [V] を設定する.
配列でまとめて電圧をを与えることもできる.
実際は最大電圧[V](30, 60, 90)とポテンショメータ[-](1-127)が設定値となるが，この関数は自動計算してくれる．

#Example

```
# ch1 の出力電圧を10Vに変更
setvoltage(dev, 1_ch, 10)

# ch1, 2, 3, 4 の出力電圧を5Vに変更
setvoltage(dev, [5, 5, 5, 5])
```
"""
setvolatge(dev, channel::Channel, voltage) = begin
	@assert voltage≤_safty_voltage[] """ !!!Dangerous!!!
		Voltage($voltage V) must be smaller than $(_safty_voltage[]) V.
		If you want more high voltage. Please use `increase_saftyvoltage(maximum_voltage)` method"""
	@assert channel ∈ (1_ch:4_ch) "The value of channel must be 1_ch ~ 4_ch"
	ch = channel.num
	V = voltage>60 ? 90 : voltage>30 ? 60 : 30
	P = (127 * voltage) ÷ V |> Int
	duty = dev.status[:burst_duty][ch]
	fr = dev.status[:burst_frequency][ch]
	send( dev, :B; ch, V, P, fr, duty, type=0, step=1 )
	dev.status[:voltage][ch] = (V, P)
	dev.status
end

for _func in (:setburstduty, :setburstfreqency, :setvolatge)
	@eval $(_func)(dev, (v1, v2, v3, v4)) = begin
		$(_func)(dev, 1_ch, v1)
		$(_func)(dev, 2_ch, v2)
		$(_func)(dev, 3_ch, v3)
		$(_func)(dev, 4_ch, v4)
	end
end

#* Cコマンドのラッパー
"""
	switchON(dev::Stimulator,    ports_on::AbstractVector{Port})
	switchON(dev::Stimulator, T, ports_on::AbstractVector{Port})

指定したポートのスイッチをオンにする．

#Example

```
# port1, 2 のスイッチをオンにする
switchON(dev, 1_ch, 10)

# ch1, 2, 3, 4 の出力電圧を5Vに変更
setvoltage(dev, [5, 5, 5, 5])
```
"""
switchON(dev, ports_on::AbstractVector{Port}) = begin
	on_off = [ n_p ∈ ports_on for n_p in 1_p:25_p ]
	connections = dev.status[:ports_connection] 
	send( dev, :C; connections, on_off)
	dev.status[:ports_on_off] = on_off
	dev.status
end
switchON(dev, T, ports_on::AbstractVector{Port}) = begin
	@assert T≤_safty_time[] """ !!!Dangerous!!!
		Stimulus time ($T s) must be smaller than $(_safty_time[]) V.
		If you want longer time. Please use `increase_saftytime(maximum_stimulus_time)` method"""
	switchON(dev, ports_on)
	sleep(T)
	switchOFF(dev)
end
"""
	switchOFF(dev, ports_off::AbstractVector{Port}) = switchON(dev, filter( p->p∉ports_off, 1_p:25_p ))
	switchOFF(dev) = switchOFF(dev, 1_p:25_p)
"""
switchOFF(dev, ports_off::AbstractVector{Port}) = switchON(dev, filter( p->p∉ports_off, 1_p:25_p ))
switchOFF(dev) = switchOFF(dev, 1_p:25_p)

"""
	setconnections(dev, channels::AbstractVector{Channel})

	setconnections(dev, connect_pair::Pair{Channel, Port}...)
	setconnections(dev, connect_pairs::AbstractVector{Pair{Channel, Port}})

	setconnections(dev, connect_pair::Pair{Channel, P}...) where P<:(AbstractVector)
	setconnections(dev, connect_pairs::AbstractVector{Pair{Channel, P}}) where P<:(AbstractVector)

	setconnections(dev, connect_pairs::Pair{Tuple{Port, Port}, Channel}...)
	setconnections(dev, connect_pairs::AbstractVector{Pair{Tuple{Port, Port}, Channel}})

チャンネルとポートの接続を決定する．

#Example

```
# 以下3つは全て同値な書き方
setconnections( dev, 
	[-1_ch, +1_ch, -2_ch, +2_ch, -3_ch, +3_ch, -4_ch, +4_ch, -2_ch, +2_ch] 
)

setconnections( dev, [ 
	-3_ch =>  5_p, 
	+3_ch =>  6_p,
	-1_ch =>  1_p,
	+1_ch =>  2_p,
	-2_ch =>  3_p,
	+2_ch =>  4_p,
	-4_ch =>  7_p,
	+4_ch =>  8_p,
	-2_ch =>  9_p,
	+2_ch => 10_p,
] )

setconnections(dev, [
	-1_ch => [1_p],
	+1_ch => [2_p],
	-2_ch => [3_p,  9_p],
	+2_ch => [4_p, 10_p],
	-3_ch => [5_p],
	+3_ch => [6_p],
	-4_ch => [7_p],
	+4_ch => [8_p],
] )

setconnections( dev, [ 
	(5_p,  6_p) => 3_ch, 
	(1_p,  2_p) => 1_ch,
	(3_p,  4_p) => 2_ch,
	(7_p,  8_p) => 4_ch,
	(9_p, 10_p) => 2_ch,
] )
#次のような書き方もできる
setconnections( dev, -3_ch=>5_p, +3_ch=>6_p )
setconnections( dev, -2_ch=>[3_p, 9_p], +2_ch=>[4_p, 10_p])
setconnections( dev, (5_p, 6_p)=>3_ch, (9_p, 10_p)=>2_ch )

```
"""
setconnections( dev, channels::AbstractVector{Channel} ) = begin
	@assert 0 ≤ length(channels) ≤ 25 
	connections = getproperty.([channels; fill(-1_ch, 25-length(channels))], :num)
	on_off = dev.status[:ports_on_off]
	send(dev, :C; connections, on_off)
	dev.status[:ports_connection] = connections
	dev.status
end

setconnections( dev, connect_pair::Pair{Channel, Port}... ) = setconnections(dev, collect(connect_pair))
setconnections( dev, connect_pairs::AbstractVector{Pair{Channel, Port}} ) = setconnections( dev, [ ch=>[p] for (ch, p) in connect_pairs])
setconnections( dev, connect_pair::Pair{Channel, P}... ) where P<:AbstractVector = setconnections(dev, collect(connect_pair))
setconnections( dev, connect_pairs::AbstractVector{Pair{Channel, P}} ) where P<:AbstractVector = begin
	connections = dev.status[:ports_connection] .*_ch
	for (ch, ports) in connect_pairs, p in ports
		connections[p.num] = ch
	end
	setconnections(dev, connections)
end
setconnections( dev, connect_pair::Pair{Channel, P} ) where P<:AbstractVector = setconnections( dev, [connect_pair]) 

setconnections( dev, connect_pairs::Pair{Tuple{Port, Port}, Channel}... ) = setconnections( dev, collect(connect_pairs))
setconnections( dev, connect_pairs::AbstractVector{Pair{Tuple{Port, Port}, Channel}} ) = begin
	connections = dev.status[:ports_connection] .*_ch
	for (p_pair, ch) in connect_pairs
		connections[p_pair[1].num] = Channel(-ch.num)
		connections[p_pair[2].num] = Channel(+ch.num)
	end
	setconnections(dev, connections)
end

"""
	resetconnections( dev ) = setconnections( dev,fill(-1_ch, 25) )
"""
resetconnections( dev ) = setconnections( dev,fill(-1_ch, 25) )

#* Eコマンドのラッパー
"""
todo
"""
readdevice(dev) = begin 
	sleep(0.1)
	send(dev, :E)
	sleep(0.1)
	read(dev.serial) |> String |> print
end
