"""
電通大の電気刺激装置を制御するためのもの．\\
シリアル通信によって以下のコマンド（必要に応じて引数を取る）を送ることによって設定を変更することができる．\\



```
Symbol：設定内容
  - 引数１
  - 引数２
```

	
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
  - ポート別チャンネル設定 1 - 25
  - ON/OFF指定 1:ON, 0:OFF
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

詳細は電気刺激装置説明書参照
"""
module ElectroStimulatorControllers

export Stimulator
export send

using SerialPorts	
using Logging

const baudrate = 230400 #刺激装置側の都合でこれは固定
mutable struct Stimulator 
	serial
	status
	Stimulator(port) = begin
		try 
			x=new(SerialPort(port, baudrate), Dict{Symbol, Any}())
			finalizer(x) do x
				close(x.serial)
				@async println("closed the port \"$port\"") #なぜか@asyncを入れろとのこと．
			end
			x
		catch
			@error "failure to open serial port \"$port\""
			@info "now avalable serial port are listed as follows:\n $(list_serialports())"
		end
	end
end
Base.show(io::IO, x::Stimulator) = dump(IOContext(io, :limit => true), x, maxdepth=1)

include("primitive.jl")
include("wraped.jl")

end