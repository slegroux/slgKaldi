import grpc
from random import randint
from timeit import default_timer as timer
import diarization_pb2, diarization_pb2_grpc

start_ch = timer()
channel = grpc.insecure_channel('localhost:50051')
stub = diarization_pb2_grpc.DiarizeStub(channel)
end_ch = timer()

audio_path = 'data/audio/diarizationExample.wav'
n_speakers = 4
n_files = 3

start = timer()
for i in range(5):
    request = diarization_pb2.Input(audio_path = audio_path, n_speakers = n_speakers)
    response = stub.diarize_from_wav(request)

print("done")
end = timer()

all_time = end - start
ch_time = end_ch - start_ch
print ('Time spent for {} predictions is {}'.format(n_files,(all_time)))
print('In average, {} second for each prediction'.format(all_time/n_files))
print('That means you can do {} predictions in one second'.format(int(1/(all_time/n_files))))
print('Time for connecting to server = {}'.format(ch_time))