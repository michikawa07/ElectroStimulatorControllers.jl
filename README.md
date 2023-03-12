# ElectroStimulatorControllers.jl

## sample
あとで追加します．

```julia
function sample1()
	dev = Stimulator("COM5")
	try
		switchOFF( dev )
		setvolatge( dev, [0, 0, 0, 0])
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
		readdevice( dev ) #確認
		setvolatge( dev, 1_ch, 5)
		switchON( dev, 4, [1_p, 2_p, 5_p, 6_p] ) # ポート1, 2, 5, 6を4秒間ONにする
		readdevice( dev ) #確認
	catch e 
		rethrow(e)
	finally
		switchOFF( dev )
		finalize(dev)
	end
end	
```
