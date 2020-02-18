import grpc
from concurrent import futures
import time

import diarization_pb2, diarization_pb2_grpc
import diarize

class DiarizeServicer(diarization_pb2_grpc.DiarizeServicer):
    def diarize_from_wav(self, request, context):
        response = diarization_pb2.Output()
        response.file_path = diarize.diarize(request.audio_path, request.n_speakers)
        return(response)

server = grpc.server(futures.ThreadPoolExecutor(max_workers=5))
diarization_pb2_grpc.add_DiarizeServicer_to_server(DiarizeServicer(), server)
print("listen port 5051")
server.add_insecure_port('[::]:50051')
server.start()

try:
    while True:
        time.sleep(86400)
except KeyboardInterrupt:
    server.stop(0)