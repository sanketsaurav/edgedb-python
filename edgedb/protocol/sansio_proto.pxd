#
# This source file is part of the EdgeDB open source project.
#
# Copyright 2016-present MagicStack Inc. and the EdgeDB authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


cimport cython
cimport cpython

from libc.stdint cimport int16_t, int32_t, uint16_t, \
                         uint32_t, int64_t, uint64_t

from edgedb.pgproto.pgproto cimport (
    WriteBuffer,
    ReadBuffer,
    FRBuffer,
)

from edgedb.pgproto cimport pgproto
from edgedb.pgproto.debug cimport PG_DEBUG


include "./lru.pxd"
include "./codecs/codecs.pxd"


ctypedef object (*decode_row_method)(BaseCodec, FRBuffer *buf)


cdef enum TransactionStatus:
    TRANS_IDLE = 0                 # connection idle
    TRANS_ACTIVE = 1               # command in progress
    TRANS_INTRANS = 2              # idle, within transaction block
    TRANS_INERROR = 3              # idle, within failed transaction
    TRANS_UNKNOWN = 4              # cannot determine status


cdef enum EdgeParseFlags:
    PARSE_HAS_RESULT = 1 << 0
    PARSE_SINGLETON_RESULT = 1 << 1


cdef class QueryCache:

    cdef:
        LRUMapping queries

    cdef get(self, str query, bint json_mode)
    cdef set(self, str query, bint json_mode,
             int32_t parse_flags,
             BaseCodec in_type, BaseCodec out_type)


cdef class SansIOProtocol:

    cdef:
        ReadBuffer buffer

        bint connected

        readonly object addr
        readonly object con_params

        object backend_secret

        TransactionStatus xact_status

    cdef encode_args(self, BaseCodec in_dc, WriteBuffer buf, args, kwargs)

    cdef parse_data_messages(self, BaseCodec out_dc, result)
    cdef parse_sync_message(self)
    cdef parse_describe_type_message(self, CodecsRegistry reg)
    cdef parse_error_message(self)