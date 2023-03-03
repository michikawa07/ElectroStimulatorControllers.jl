"""
# 電通大の電気刺激装置を制御するためのもの．\\

## 概要
本体装置に対していくつかのコマンドを送ることで内部の設定を書き換えることで制御する.
ここでコマンドとは，規定の文法からなる文字列をシリアル通信で送ることを指す．\\
公式のGUIが付属しているが，あまり使い勝手がいいとは言えないため，このパッケージを作製した．

## コマンド詳細
本当の詳細についてはGUIに付属の説明書(電気刺激装置説明書参照.xls)を参照のこと．\\
簡単な文法で文字列を組み立てればいいのだが，毎回毎回やると非常に面倒．
本パッケージのを使う主な利点は_面倒な文字列生成を肩代わりしてくれる_ことにある．

使う上では，次のように，コマンドの種類を表すSymbolと引数についてだけ知っていればよい．

### コマンドの種類

凡例
```
Symbol：設定内容
  - 引数１
  - 引数２
```

リスト
```
A: キャリア周波数設定
  - キャリア周波数 1000 - 24000
  - キャリアONデューティー 0 - 100
B: 各チャンネル設定 
  - 電圧値 30, 60, 90
  - ポテンショメータ 0 - 127
  - バースト周波数 0 - 400
  - バーストONデューティー 0～100
  - 波形タイプ 0：方形, 1：正弦, 2：三角
  - 波形可変ステップ 1, 2, 4, 5
C: 刺激信号個別選択 
  - ポート別チャンネル設定 ±1, ±2, ±3, ±4 (25個)
  - ON/OFF指定 1:ON, 0:OFF (25個)
E: 各情報読み出し
F: EEPROM設定書き込み
G: EEPROM設定読み出し
H: デフォルト設定
J: バッチ処理設定
  - 別途詳細参照 
K: バッチ処理開始
L: バッチ処理停止
Z: パワーオンリセット
```

note 2023/02/13追記:\\
さらに面倒に感じたので，コマンドの種類なども覚えないですむようにしました．
次節参照.

## 上記コマンドの wrapper method
記号Aが何で，記号Bが何で...って覚えるの面倒だったので，
直接的に"キャリア周波数設定"などに対応する関数を作成しました・


"""
module ElectroStimulatorControllers

using LibSerialPort	# シリアル通信をするための物   
using Logging     	# 表示用

export Stimulator, close

"""
	Stimulator(USB_port_name::String)

## Example

```
device = Stimulator("COM2")
```

## Usage 

USBポートCOM2に接続されたデバイスのキャリア周波数を10000に，キャリアduty比を50%に設定する場合

```
# コマンド風に使う場合
send(device, :A, fr=10000, duty=50)

# 個別のメソッドで呼ぶ場合（上と同じ）
setcarrierfrequency(device, 10000)
setcarrierduty(device, 50)
```

USBポートCOM2に接続されたデバイスの各情報を読み出す場合

```
# コマンド風に使う場合
send(device, :E)
readavailable(device.serial) |> print

# 個別のメソッドで呼ぶ場合（上と同じ）
readdevice(device)
```

"""
mutable struct Stimulator 
	serial
	status
	Stimulator(port) = begin
		try 
			baudrate = 230400 #刺激装置側の都合でこれは固定
			serial_port = LibSerialPort.open(port, baudrate)
			x=new(serial_port, Dict{Symbol, Any}(
				:carrier_frequency => 2000,	
				:carrier_duty => 50,	
				:burst_frequency => fill(100, 4),	
				:burst_duty => fill(30, 4),	
				:voltage => fill((30, 0), 4),	
				:ports_connection => fill(-1, 25),	
				:ports_on_off => falses(25),	
			))
			finalizer(x) do x
				close(x)
				@async println("closed the port \"$port\"") #なぜか@asyncを入れろとのこと．
				sleep(0.01)
				return x
			end
			x
		catch e
			port ∉ get_port_list() && return @error """
				Failure to open serial port "$port" 
				Now avalable serial port are listed as follows:\n $( get_port_list() )"""
			rethrow(e)
		end
	end
	Stimulator() = @error """Now avalable serial port are listed as follows:\n $( get_port_list() )"""
end
Base.show(io::IO, x::Stimulator) = dump(IOContext(io, :limit => true), x, maxdepth=1)

Base.close(dev::Stimulator) = close(dev.serial)

open(f, port::String) = begin
	device = Stimulator(port)
	f(device)
	finalize(device)
end

include("primitive.jl")
include("wrapped.jl")

end