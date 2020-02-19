#!/usr/bin/env python

import grpc
from random import randint
from timeit import default_timer as timer
import diarization_pb2, diarization_pb2_grpc
import argparse

def run(host, port, audio_path, n_speakers):

    channel = grpc.insecure_channel(host +':' + str(port))
    stub = diarization_pb2_grpc.DiarizeStub(channel)
    request = diarization_pb2.Input(audio_path=audio_path, n_speakers=n_speakers)
    response = stub.diarize_from_wav(request)
    print(response.file_path)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='diarization client')
    parser.add_argument('audio_path', type=str)
    parser.add_argument('n_speakers', type=int)
    parser.add_argument('--host', help='host name', default='localhost', type=str)
    parser.add_argument('--port', help='port number', default=50051, type=int)
    args = parser.parse_args()
    run(args.host, args.port, args.audio_path, args.n_speakers)