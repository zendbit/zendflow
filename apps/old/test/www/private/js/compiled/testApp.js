/* Generated by the Nim Compiler v1.2.0 */
var framePtr = null;
var excHandler = 0;
var lastJSError = null;
if (typeof Int8Array === 'undefined') Int8Array = Array;
if (typeof Int16Array === 'undefined') Int16Array = Array;
if (typeof Int32Array === 'undefined') Int32Array = Array;
if (typeof Uint8Array === 'undefined') Uint8Array = Array;
if (typeof Uint16Array === 'undefined') Uint16Array = Array;
if (typeof Uint32Array === 'undefined') Uint32Array = Array;
if (typeof Float32Array === 'undefined') Float32Array = Array;
if (typeof Float64Array === 'undefined') Float64Array = Array;
var NTI6253 = {size: 0, kind: 17, base: null, node: null, finalizer: null};
var NTI6249 = {size: 0, kind: 17, base: null, node: null, finalizer: null};
var NTI6233 = {size: 0, kind: 17, base: null, node: null, finalizer: null};
var NTI6237 = {size: 0, kind: 17, base: null, node: null, finalizer: null};
var NTI9345015 = {size: 0,kind: 24,base: null,node: null,finalizer: null};
var NTI143 = {size: 0,kind: 31,base: null,node: null,finalizer: null};
var NTI160043 = {size: 0, kind: 18, base: null, node: null, finalizer: null};
var NTI6286 = {size: 0,kind: 22,base: null,node: null,finalizer: null};
var NTI114 = {size: 0,kind: 29,base: null,node: null,finalizer: null};
var NTI6281 = {size: 0,kind: 22,base: null,node: null,finalizer: null};
var NTI6217 = {size: 0, kind: 17, base: null, node: null, finalizer: null};
var NTI6219 = {size: 0, kind: 17, base: null, node: null, finalizer: null};
var NTI6241 = {size: 0, kind: 17, base: null, node: null, finalizer: null};
var NTI112 = {size: 0,kind: 28,base: null,node: null,finalizer: null};
var NTI6008 = {size: 0, kind: 17, base: null, node: null, finalizer: null};
var NTI6291 = {size: 0, kind: 17, base: null, node: null, finalizer: null};
var NTI1135097 = {size: 0, kind: 17, base: null, node: null, finalizer: null};
var NTI1282017 = {size: 0, kind: 17, base: null, node: null, finalizer: null};
var NNI1282017 = {kind: 2, len: 0, offset: 0, typ: null, name: null, sons: []};
NTI1282017.node = NNI1282017;
var NNI1135097 = {kind: 2, len: 0, offset: 0, typ: null, name: null, sons: []};
NTI1135097.node = NNI1135097;
var NNI6291 = {kind: 2, len: 0, offset: 0, typ: null, name: null, sons: []};
NTI6291.node = NNI6291;
var NNI6008 = {kind: 2, len: 0, offset: 0, typ: null, name: null, sons: []};
NTI6008.node = NNI6008;
NTI6291.base = NTI6008;
NTI1135097.base = NTI6291;
NTI1282017.base = NTI1135097;
var NNI6241 = {kind: 2, len: 0, offset: 0, typ: null, name: null, sons: []};
NTI6241.node = NNI6241;
var NNI6219 = {kind: 2, len: 0, offset: 0, typ: null, name: null, sons: []};
NTI6219.node = NNI6219;
NTI6281.base = NTI6217;
NTI6286.base = NTI6217;
var NNI6217 = {kind: 2, len: 5, offset: 0, typ: null, name: null, sons: [{kind: 1, offset: "parent", len: 0, typ: NTI6281, name: "parent", sons: null}, 
{kind: 1, offset: "name", len: 0, typ: NTI114, name: "name", sons: null}, 
{kind: 1, offset: "message", len: 0, typ: NTI112, name: "msg", sons: null}, 
{kind: 1, offset: "trace", len: 0, typ: NTI112, name: "trace", sons: null}, 
{kind: 1, offset: "up", len: 0, typ: NTI6286, name: "up", sons: null}]};
NTI6217.node = NNI6217;
NTI6217.base = NTI6008;
NTI6219.base = NTI6217;
NTI6241.base = NTI6219;
var NNI160043 = {kind: 2, len: 2, offset: 0, typ: null, name: null, sons: [{kind: 1, offset: "Field0", len: 0, typ: NTI114, name: "Field0", sons: null}, 
{kind: 1, offset: "Field1", len: 0, typ: NTI143, name: "Field1", sons: null}]};
NTI160043.node = NNI160043;
NTI9345015.base = NTI112;
var NNI6237 = {kind: 2, len: 0, offset: 0, typ: null, name: null, sons: []};
NTI6237.node = NNI6237;
var NNI6233 = {kind: 2, len: 0, offset: 0, typ: null, name: null, sons: []};
NTI6233.node = NNI6233;
NTI6233.base = NTI6219;
NTI6237.base = NTI6233;
var NNI6249 = {kind: 2, len: 0, offset: 0, typ: null, name: null, sons: []};
NTI6249.node = NNI6249;
NTI6249.base = NTI6219;
var NNI6253 = {kind: 2, len: 0, offset: 0, typ: null, name: null, sons: []};
NTI6253.node = NNI6253;
NTI6253.base = NTI6219;
function toJSStr(s_225096) {
                    var Tmp5;
            var Tmp7;

  var result_225097 = null;

    var res_225170 = new_seq_225128((s_225096 != null ? s_225096.length : 0));
    var i_225172 = 0;
    var j_225174 = 0;
    L1: do {
        L2: while (true) {
        if (!(i_225172 < (s_225096 != null ? s_225096.length : 0))) break L2;
          var c_225175 = s_225096[i_225172];
          if ((c_225175 < 128)) {
          res_225170[j_225174] = String.fromCharCode(c_225175);
          i_225172 += 1;
          }
          else {
            var helper_225198 = new_seq_225128(0);
            L3: do {
                L4: while (true) {
                if (!true) break L4;
                  var code_225199 = c_225175.toString(16);
                  if (((code_225199 != null ? code_225199.length : 0) == 1)) {
                  if (helper_225198 != null) { helper_225198.push("%0"); } else { helper_225198 = ["%0"]; };
                  }
                  else {
                  if (helper_225198 != null) { helper_225198.push("%"); } else { helper_225198 = ["%"]; };
                  }
                  
                  if (helper_225198 != null) { helper_225198.push(code_225199); } else { helper_225198 = [code_225199]; };
                  i_225172 += 1;
                    if (((s_225096 != null ? s_225096.length : 0) <= i_225172)) Tmp5 = true; else {                      Tmp5 = (s_225096[i_225172] < 128);                    }                  if (Tmp5) {
                  break L3;
                  }
                  
                  c_225175 = s_225096[i_225172];
                }
            } while(false);
++excHandler;
            Tmp7 = framePtr;
            try {
            res_225170[j_225174] = decodeURIComponent(helper_225198.join(""));
--excHandler;
} catch (EXC) {
 var prevJSError = lastJSError;
 lastJSError = EXC;
 --excHandler;
            framePtr = Tmp7;
            res_225170[j_225174] = helper_225198.join("");
            lastJSError = prevJSError;
            } finally {
            framePtr = Tmp7;
            }
          }
          
          j_225174 += 1;
        }
    } while(false);
    if (res_225170 === null) res_225170 = [];
               if (res_225170.length < j_225174) { for (var i=res_225170.length;i<j_225174;++i) res_225170.push(null); }
               else { res_225170.length = j_225174; };
    result_225097 = res_225170.join("");

  return result_225097;

}
function makeNimstrLit(c_225062) {
      var ln = c_225062.length;
  var result = new Array(ln);
  for (var i = 0; i < ln; ++i) {
    result[i] = c_225062.charCodeAt(i);
  }
  return result;
  

  
}
function setConstr() {
        var result = {};
    for (var i = 0; i < arguments.length; ++i) {
      var x = arguments[i];
      if (typeof(x) == "object") {
        for (var j = x[0]; j <= x[1]; ++j) {
          result[j] = true;
        }
      } else {
        result[x] = true;
      }
    }
    return result;
  

  
}
var ConstSet1 = setConstr(17, 16, 4, 18, 27, 19, 23, 22, 21);
function nimCopy(dest_240023, src_240024, ti_240025) {
  var result_245219 = null;

    switch (ti_240025.kind) {
    case 21:
    case 22:
    case 23:
    case 5:
      if (!(is_fat_pointer_235401(ti_240025))) {
      result_245219 = src_240024;
      }
      else {
        result_245219 = [src_240024[0], src_240024[1]];
      }
      
      break;
    case 19:
            if (dest_240023 === null || dest_240023 === undefined) {
        dest_240023 = {};
      }
      else {
        for (var key in dest_240023) { delete dest_240023[key]; }
      }
      for (var key in src_240024) { dest_240023[key] = src_240024[key]; }
      result_245219 = dest_240023;
    
      break;
    case 18:
    case 17:
      if (!((ti_240025.base == null))) {
      result_245219 = nimCopy(dest_240023, src_240024, ti_240025.base);
      }
      else {
      if ((ti_240025.kind == 17)) {
      result_245219 = (dest_240023 === null || dest_240023 === undefined) ? {m_type: ti_240025} : dest_240023;
      }
      else {
        result_245219 = (dest_240023 === null || dest_240023 === undefined) ? {} : dest_240023;
      }
      }
      nimCopyAux(result_245219, src_240024, ti_240025.node);
      break;
    case 24:
    case 4:
    case 27:
    case 16:
            if (src_240024 === null) {
        result_245219 = null;
      }
      else {
        if (dest_240023 === null || dest_240023 === undefined) {
          dest_240023 = new Array(src_240024.length);
        }
        else {
          dest_240023.length = src_240024.length;
        }
        result_245219 = dest_240023;
        for (var i = 0; i < src_240024.length; ++i) {
          result_245219[i] = nimCopy(result_245219[i], src_240024[i], ti_240025.base);
        }
      }
    
      break;
    case 28:
            if (src_240024 !== null) {
        result_245219 = src_240024.slice(0);
      }
    
      break;
    default: 
      result_245219 = src_240024;
      break;
    }

  return result_245219;

}
function arrayConstr(len_250067, value_250068, typ_250069) {
        var result = new Array(len_250067);
    for (var i = 0; i < len_250067; ++i) result[i] = nimCopy(null, value_250068, typ_250069);
    return result;
  

  
}
function cstrToNimstr(c_225079) {
      var ln = c_225079.length;
  var result = new Array(ln);
  var r = 0;
  for (var i = 0; i < ln; ++i) {
    var ch = c_225079.charCodeAt(i);

    if (ch < 128) {
      result[r] = ch;
    }
    else {
      if (ch < 2048) {
        result[r] = (ch >> 6) | 192;
      }
      else {
        if (ch < 55296 || ch >= 57344) {
          result[r] = (ch >> 12) | 224;
        }
        else {
            ++i;
            ch = 65536 + (((ch & 1023) << 10) | (c_225079.charCodeAt(i) & 1023));
            result[r] = (ch >> 18) | 240;
            ++r;
            result[r] = ((ch >> 12) & 63) | 128;
        }
        ++r;
        result[r] = ((ch >> 6) & 63) | 128;
      }
      ++r;
      result[r] = (ch & 63) | 128;
    }
    ++r;
  }
  return result;
  

  
}
function raiseException(e_190218, ename_190219) {
    e_190218.name = ename_190219;
    if ((excHandler == 0)) {
    unhandledException(e_190218);
    }
    
    e_190218.trace = nimCopy(null, raw_write_stack_trace_180059(), NTI112);
    throw e_190218;

  
}
function addInt(a_230403, b_230404) {
        var result = a_230403 + b_230404;
    if (result > 2147483647 || result < -2147483648) raiseOverflow();
    return result;
  

  
}
function chckIndx(i_250086, a_250087, b_250088) {
      var Tmp1;

  var result_250089 = 0;

  BeforeRet: do {
      if (!(a_250087 <= i_250086)) Tmp1 = false; else {        Tmp1 = (i_250086 <= b_250088);      }    if (Tmp1) {
    result_250089 = i_250086;
    break BeforeRet;
    }
    else {
    raiseIndexError(i_250086, a_250087, b_250088);
    }
    
  } while (false);

  return result_250089;

}
function nimMax(a_230821, b_230822) {
    var Tmp1;

  var result_230823 = 0;

  BeforeRet: do {
    if ((b_230822 <= a_230821)) {
    Tmp1 = a_230821;
    }
    else {
    Tmp1 = b_230822;
    }
    
    result_230823 = Tmp1;
    break BeforeRet;
  } while (false);

  return result_230823;

}
function subInt(a_230421, b_230422) {
        var result = a_230421 - b_230422;
    if (result > 2147483647 || result < -2147483648) raiseOverflow();
    return result;
  

  
}
function nimMin(a_230803, b_230804) {
    var Tmp1;

  var result_230805 = 0;

  BeforeRet: do {
    if ((a_230803 <= b_230804)) {
    Tmp1 = a_230803;
    }
    else {
    Tmp1 = b_230804;
    }
    
    result_230805 = Tmp1;
    break BeforeRet;
  } while (false);

  return result_230805;

}
function mnewString(len_230044) {
        return new Array(len_230044);
  

  
}
function chckRange(i_255016, a_255017, b_255018) {
      var Tmp1;

  var result_255019 = 0;

  BeforeRet: do {
      if (!(a_255017 <= i_255016)) Tmp1 = false; else {        Tmp1 = (i_255016 <= b_255018);      }    if (Tmp1) {
    result_255019 = i_255016;
    break BeforeRet;
    }
    else {
    raiseRangeError();
    }
    
  } while (false);

  return result_255019;

}
function mulInt(a_230439, b_230440) {
        var result = a_230439 * b_230440;
    if (result > 2147483647 || result < -2147483648) raiseOverflow();
    return result;
  

  
}
function rawEcho() {
          var buf = "";
      for (var i = 0; i < arguments.length; ++i) {
        buf += toJSStr(arguments[i]);
      }
      console.log(buf);
    

  
}
var nim_program_result = 0;
var global_raise_hook_142018 = [null];
var local_raise_hook_142023 = [null];
var out_of_mem_hook_142026 = [null];
var unhandled_exception_hook_142031 = [null];
if (!Math.trunc) {
  Math.trunc = function(v) {
    v = +v;
    if (!isFinite(v)) return v;
    return (v - v % 1) || (v < 0 ? -0 : v === 0 ? v : 0);
  };
}

var object_id_860031 = [0];
function new_seq_225128(len_225131) {
  var result_225133 = null;

  var F={procname:"newSeq.newSeq",prev:framePtr,filename:"system.nim",line:0};
  framePtr = F;
    F.line = 643;
    result_225133 = new Array(len_225131); for (var i=0;i<len_225131;++i) {result_225133[i]=null;}  framePtr = F.prev;

  return result_225133;

}
function add_10050030(self_10050033, key_10050034, value_10050035) {
  var result_10050036 = null;

  var F={procname:"add.add",prev:framePtr,filename:"jObj.nim",line:0};
  framePtr = F;
  BeforeRet: do {
    F.line = 19;
    self_10050033[toJSStr(key_10050034)] = (value_10050035);
    F.line = 20;
    result_10050036 = self_10050033;
    break BeforeRet;
  } while (false);
  framePtr = F.prev;

  return result_10050036;

}
function add_10045005(self_10045008, key_10045009, value_10045010) {
  var result_10045011 = null;

  var F={procname:"add.add",prev:framePtr,filename:"jObj.nim",line:0};
  framePtr = F;
  BeforeRet: do {
    F.line = 19;
    self_10045008[toJSStr(key_10045009)] = (toJSStr(value_10045010));
    F.line = 20;
    result_10045011 = self_10045008;
    break BeforeRet;
  } while (false);
  framePtr = F.prev;

  return result_10045011;

}
function new_jobj_1282019() {
  var result_1282021 = null;

  var F={procname:"jObj.newJObj",prev:framePtr,filename:"jObj.nim",line:0};
  framePtr = F;
  BeforeRet: do {
    F.line = 16;
    result_1282021 = {m_type: NTI1282017};
    break BeforeRet;
  } while (false);
  framePtr = F.prev;

  return result_1282021;

}
function add_10090011(self_10090014, key_10090015, value_10090016) {
  var result_10090017 = null;

  var F={procname:"add.add",prev:framePtr,filename:"jObj.nim",line:0};
  framePtr = F;
  BeforeRet: do {
    F.line = 19;
    self_10090014[toJSStr(key_10090015)] = (value_10090016);
    F.line = 20;
    result_10090017 = self_10090014;
    break BeforeRet;
  } while (false);
  framePtr = F.prev;

  return result_10090017;

}
function add_10130011(self_10130014, key_10130015, value_10130016) {
  var result_10130017 = null;

  var F={procname:"add.add",prev:framePtr,filename:"jObj.nim",line:0};
  framePtr = F;
  BeforeRet: do {
    F.line = 19;
    self_10130014[toJSStr(key_10130015)] = (value_10130016);
    F.line = 20;
    result_10130017 = self_10130014;
    break BeforeRet;
  } while (false);
  framePtr = F.prev;

  return result_10130017;

}
function add_10170034(self_10170037, key_10170038, value_10170039) {
  var result_10170040 = null;

  var F={procname:"add.add",prev:framePtr,filename:"jObj.nim",line:0};
  framePtr = F;
  BeforeRet: do {
    F.line = 19;
    self_10170037[toJSStr(key_10170038)] = (value_10170039);
    F.line = 20;
    result_10170040 = self_10170037;
    break BeforeRet;
  } while (false);
  framePtr = F.prev;

  return result_10170040;

}
function add_10210092(self_10210095, key_10210096, value_10210097) {
  var result_10210098 = null;

  var F={procname:"add.add",prev:framePtr,filename:"jObj.nim",line:0};
  framePtr = F;
  BeforeRet: do {
    F.line = 19;
    self_10210095[toJSStr(key_10210096)] = (value_10210097);
    F.line = 20;
    result_10210098 = self_10210095;
    break BeforeRet;
  } while (false);
  framePtr = F.prev;

  return result_10210098;

}
function is_fat_pointer_235401(ti_235403) {
  var result_235404 = false;

  BeforeRet: do {
    result_235404 = !((ConstSet1[ti_235403.base.kind] != undefined));
    break BeforeRet;
  } while (false);

  return result_235404;

}
function nimCopyAux(dest_240028, src_240029, n_240031) {
    switch (n_240031.kind) {
    case 0:
      break;
    case 1:
            dest_240028[n_240031.offset] = nimCopy(dest_240028[n_240031.offset], src_240029[n_240031.offset], n_240031.typ);
    
      break;
    case 2:
          for (var i = 0; i < n_240031.sons.length; i++) {
      nimCopyAux(dest_240028, src_240029, n_240031.sons[i]);
    }
    
      break;
    case 3:
            dest_240028[n_240031.offset] = nimCopy(dest_240028[n_240031.offset], src_240029[n_240031.offset], n_240031.typ);
      for (var i = 0; i < n_240031.sons.length; ++i) {
        nimCopyAux(dest_240028, src_240029, n_240031.sons[i][1]);
      }
    
      break;
    }

  
}
function add_142042(x_142045, x_142045_Idx, y_142046) {
          if (x_142045[x_142045_Idx] === null) { x_142045[x_142045_Idx] = []; }
      var off = x_142045[x_142045_Idx].length;
      x_142045[x_142045_Idx].length += y_142046.length;
      for (var i = 0; i < y_142046.length; ++i) {
        x_142045[x_142045_Idx][off+i] = y_142046.charCodeAt(i);
      }
    

  
}
function aux_write_stack_trace_160038(f_160040) {
          var Tmp3;

  var result_160041 = [null];

    var it_160049 = f_160040;
    var i_160051 = 0;
    var total_160053 = 0;
    var temp_frames_160060 = arrayConstr(64, {Field0: null, Field1: 0}, NTI160043);
    L1: do {
        L2: while (true) {
          if (!!((it_160049 == null))) Tmp3 = false; else {            Tmp3 = (i_160051 <= 63);          }        if (!Tmp3) break L2;
          temp_frames_160060[i_160051].Field0 = it_160049.procname;
          temp_frames_160060[i_160051].Field1 = it_160049.line;
          i_160051 += 1;
          total_160053 += 1;
          it_160049 = it_160049.prev;
        }
    } while(false);
    L4: do {
        L5: while (true) {
        if (!!((it_160049 == null))) break L5;
          total_160053 += 1;
          it_160049 = it_160049.prev;
        }
    } while(false);
    result_160041[0] = nimCopy(null, [], NTI112);
    if (!((total_160053 == i_160051))) {
    if (result_160041[0] != null) { result_160041[0] = (result_160041[0]).concat(makeNimstrLit("(")); } else { result_160041[0] = makeNimstrLit("("); };
    if (result_160041[0] != null) { result_160041[0] = (result_160041[0]).concat(cstrToNimstr(((total_160053 - i_160051))+"")); } else { result_160041[0] = cstrToNimstr(((total_160053 - i_160051))+"").slice(); };
    if (result_160041[0] != null) { result_160041[0] = (result_160041[0]).concat(makeNimstrLit(" calls omitted) ...\x0A")); } else { result_160041[0] = makeNimstrLit(" calls omitted) ...\x0A"); };
    }
    
    L6: do {
      var j_175236 = 0;
      var colontmp__10285106 = 0;
      colontmp__10285106 = (i_160051 - 1);
      var res_10285107 = colontmp__10285106;
      L7: do {
          L8: while (true) {
          if (!(0 <= res_10285107)) break L8;
            j_175236 = res_10285107;
            add_142042(result_160041, 0, temp_frames_160060[j_175236].Field0);
            if ((0 < temp_frames_160060[j_175236].Field1)) {
            if (result_160041[0] != null) { result_160041[0] = (result_160041[0]).concat(makeNimstrLit(", line: ")); } else { result_160041[0] = makeNimstrLit(", line: "); };
            if (result_160041[0] != null) { result_160041[0] = (result_160041[0]).concat(cstrToNimstr((temp_frames_160060[j_175236].Field1)+"")); } else { result_160041[0] = cstrToNimstr((temp_frames_160060[j_175236].Field1)+"").slice(); };
            }
            
            if (result_160041[0] != null) { result_160041[0] = (result_160041[0]).concat(makeNimstrLit("\x0A")); } else { result_160041[0] = makeNimstrLit("\x0A"); };
            res_10285107 -= 1;
          }
      } while(false);
    } while(false);

  return result_160041[0];

}
function raw_write_stack_trace_180059() {
  var result_180061 = null;

    if (!((framePtr == null))) {
    result_180061 = nimCopy(null, (makeNimstrLit("Traceback (most recent call last)\x0A") || []).concat(aux_write_stack_trace_160038(framePtr) || []), NTI112);
    }
    else {
      result_180061 = nimCopy(null, makeNimstrLit("No stack traceback available\x0A"), NTI112);
    }
    

  return result_180061;

}
function unhandledException(e_185059) {
    var buf_185060 = [[]];
    if (!(((e_185059.message != null ? e_185059.message.length : 0) == 0))) {
    if (buf_185060[0] != null) { buf_185060[0] = (buf_185060[0]).concat(makeNimstrLit("Error: unhandled exception: ")); } else { buf_185060[0] = makeNimstrLit("Error: unhandled exception: "); };
    if (buf_185060[0] != null) { buf_185060[0] = (buf_185060[0]).concat(e_185059.message); } else { buf_185060[0] = e_185059.message.slice(); };
    }
    else {
    if (buf_185060[0] != null) { buf_185060[0] = (buf_185060[0]).concat(makeNimstrLit("Error: unhandled exception")); } else { buf_185060[0] = makeNimstrLit("Error: unhandled exception"); };
    }
    
    if (buf_185060[0] != null) { buf_185060[0] = (buf_185060[0]).concat(makeNimstrLit(" [")); } else { buf_185060[0] = makeNimstrLit(" ["); };
    add_142042(buf_185060, 0, e_185059.name);
    if (buf_185060[0] != null) { buf_185060[0] = (buf_185060[0]).concat(makeNimstrLit("]\x0A")); } else { buf_185060[0] = makeNimstrLit("]\x0A"); };
    if (buf_185060[0] != null) { buf_185060[0] = (buf_185060[0]).concat(raw_write_stack_trace_180059()); } else { buf_185060[0] = raw_write_stack_trace_180059().slice(); };
    var cbuf_190201 = toJSStr(buf_185060[0]);
    framePtr = null;
      if (typeof(Error) !== "undefined") {
    throw new Error(cbuf_190201);
  }
  else {
    throw cbuf_190201;
  }
  

  
}
function sys_fatal_102618(message_102622) {
  var F={procname:"sysFatal.sysFatal",prev:framePtr,filename:"fatal.nim",line:0};
  framePtr = F;
    F.line = 49;
    raiseException({message: nimCopy(null, message_102622, NTI112), m_type: NTI6241, parent: null, name: null, trace: null, up: null}, "AssertionError");
  framePtr = F.prev;

  
}
function raise_assert_102614(msg_102616) {
  var F={procname:"assertions.raiseAssert",prev:framePtr,filename:"assertions.nim",line:0};
  framePtr = F;
    F.line = 22;
    sys_fatal_102618(msg_102616);
  framePtr = F.prev;

  
}
function failed_assert_impl_102680(msg_102682) {
  var F={procname:"assertions.failedAssertImpl",prev:framePtr,filename:"assertions.nim",line:0};
  framePtr = F;
    F.line = 29;
    raise_assert_102614(msg_102682);
  framePtr = F.prev;

  
}
function raiseOverflow() {
    raiseException({message: makeNimstrLit("over- or underflow"), parent: null, m_type: NTI6237, name: null, trace: null, up: null}, "OverflowError");

  
}
function raiseIndexError(i_210047, a_210048, b_210049) {
    var Tmp1;

    if ((b_210049 < a_210048)) {
    Tmp1 = makeNimstrLit("index out of bounds, the container is empty");
    }
    else {
    Tmp1 = (makeNimstrLit("index ") || []).concat(cstrToNimstr((i_210047)+"") || [],makeNimstrLit(" not in ") || [],cstrToNimstr((a_210048)+"") || [],makeNimstrLit(" .. ") || [],cstrToNimstr((b_210049)+"") || []);
    }
    
    raiseException({message: nimCopy(null, Tmp1, NTI112), parent: null, m_type: NTI6249, name: null, trace: null, up: null}, "IndexError");

  
}
function substr_eq_9150026(s_9150028, pos_9150029, substr_9150030) {
  var result_9150031 = false;

  var F={procname:"strutils.substrEq",prev:framePtr,filename:"strutils.nim",line:0};
  framePtr = F;
  BeforeRet: do {
    F.line = 365;
    var i_9150033 = 0;
    F.line = 366;
    var length_9150034 = (substr_9150030 != null ? substr_9150030.length : 0);
    L1: do {
      F.line = 367;
        L2: while (true) {
        if (!(((i_9150033 < length_9150034) && (addInt(pos_9150029, i_9150033) < (s_9150028 != null ? s_9150028.length : 0))) && (s_9150028[chckIndx(addInt(pos_9150029, i_9150033), 0, (s_9150028 != null ? s_9150028.length : 0)+0-1)-0] == substr_9150030[chckIndx(i_9150033, 0, (substr_9150030 != null ? substr_9150030.length : 0)+0-1)-0]))) break L2;
          F.line = 368;
          i_9150033 = addInt(i_9150033, 1);
        }
    } while(false);
    F.line = 369;
    result_9150031 = (i_9150033 == length_9150034);
    break BeforeRet;
  } while (false);
  framePtr = F.prev;

  return result_9150031;

}
function raiseRangeError() {
    raiseException({message: makeNimstrLit("value out of range"), parent: null, m_type: NTI6253, name: null, trace: null, up: null}, "RangeError");

  
}
function substr_341022(s_341024, first_341025, last_341026) {
  var result_341027 = null;

  var F={procname:"system.substr",prev:framePtr,filename:"system.nim",line:0};
  framePtr = F;
    F.line = 2943;
    var first_341028 = nimMax(first_341025, 0);
    F.line = 2944;
    var l_341030 = nimMax(addInt(subInt(nimMin(last_341026, (s_341024 != null ? (s_341024.length-1) : -1)), first_341028), 1), 0);
    F.line = 2945;
    result_341027 = nimCopy(null, mnewString(chckRange(l_341030, 0, 2147483647)), NTI112);
    L1: do {
      F.line = 2946;
      var i_341039 = 0;
      F.line = 66;
      var colontmp__10285124 = 0;
      F.line = 2946;
      colontmp__10285124 = subInt(l_341030, 1);
      F.line = 77;
      var res_10285125 = 0;
      L2: do {
        F.line = 78;
          L3: while (true) {
          if (!(res_10285125 <= colontmp__10285124)) break L3;
            F.line = 2946;
            i_341039 = res_10285125;
            F.line = 2947;
            result_341027[chckIndx(i_341039, 0, (result_341027 != null ? result_341027.length : 0)+0-1)-0] = s_341024[chckIndx(addInt(i_341039, first_341028), 0, (s_341024 != null ? s_341024.length : 0)+0-1)-0];
            F.line = 80;
            res_10285125 = addInt(res_10285125, 1);
          }
      } while(false);
    } while(false);
  framePtr = F.prev;

  return result_341027;

}
function nsuSplitString(s_9325039, sep_9325040, maxsplit_9325041) {
  var result_9325043 = null;

  var F={procname:"strutils.split",prev:framePtr,filename:"strutils.nim",line:0};
  framePtr = F;
    if (!((0 < (sep_9325040 != null ? sep_9325040.length : 0)))) {
    F.line = 756;
    failed_assert_impl_102680(makeNimstrLit("/Volumes/Data/Users/amru/.choosenim/toolchains/nim-1.2.0/lib/pure/strutils.nim(756, 11) `sep.len > 0` "));
    }
    
    F.line = 410;
    result_9325043 = nimCopy(null, [], NTI9345015);
    L1: do {
      F.line = 411;
      var xHEX60gensym9340201_9345016 = null;
      F.line = 382;
      var lastHEX60gensym9185043_10285096 = 0;
      F.line = 383;
      var splitsHEX60gensym9185044_10285097 = maxsplit_9325041;
      L2: do {
        F.line = 516;
          L3: while (true) {
          if (!(lastHEX60gensym9185043_10285096 <= (s_9325039 != null ? s_9325039.length : 0))) break L3;
            F.line = 386;
            var firstHEX60gensym9185045_10285099 = lastHEX60gensym9185043_10285096;
            L4: do {
              F.line = 387;
                L5: while (true) {
                if (!((lastHEX60gensym9185043_10285096 < (s_9325039 != null ? s_9325039.length : 0)) && !(substr_eq_9150026(s_9325039, lastHEX60gensym9185043_10285096, sep_9325040)))) break L5;
                  F.line = 388;
                  lastHEX60gensym9185043_10285096 = addInt(lastHEX60gensym9185043_10285096, 1);
                }
            } while(false);
            if ((splitsHEX60gensym9185044_10285097 == 0)) {
            F.line = 389;
            lastHEX60gensym9185043_10285096 = (s_9325039 != null ? s_9325039.length : 0);
            }
            
            F.line = 758;
            xHEX60gensym9340201_9345016 = substr_341022(s_9325039, firstHEX60gensym9185045_10285099, subInt(lastHEX60gensym9185043_10285096, 1));
            F.line = 411;
            var Tmp6 = nimCopy(null, xHEX60gensym9340201_9345016, NTI112);
            if (result_9325043 != null) { result_9325043.push(Tmp6); } else { result_9325043 = [Tmp6]; };
            if ((splitsHEX60gensym9185044_10285097 == 0)) {
            F.line = 391;
            break L2;
            }
            
            F.line = 392;
            splitsHEX60gensym9185044_10285097 = subInt(splitsHEX60gensym9185044_10285097, 1);
            F.line = 393;
            lastHEX60gensym9185043_10285096 = addInt(lastHEX60gensym9185043_10285096, (sep_9325040 != null ? sep_9325040.length : 0));
          }
      } while(false);
    } while(false);
  framePtr = F.prev;

  return result_9325043;

}
function nsuJoinSep(a_9710018, sep_9710019) {
  var result_9710020 = null;

  var F={procname:"strutils.join",prev:framePtr,filename:"strutils.nim",line:0};
  framePtr = F;
    if ((0 < (a_9710018 != null ? a_9710018.length : 0))) {
    F.line = 1762;
    var l_9715009 = mulInt((sep_9710019 != null ? sep_9710019.length : 0), subInt((a_9710018 != null ? a_9710018.length : 0), 1));
    L1: do {
      F.line = 1763;
      var i_9715023 = 0;
      F.line = 66;
      var colontmp__10285132 = 0;
      F.line = 1763;
      colontmp__10285132 = (a_9710018 != null ? (a_9710018.length-1) : -1);
      F.line = 77;
      var res_10285133 = 0;
      L2: do {
        F.line = 78;
          L3: while (true) {
          if (!(res_10285133 <= colontmp__10285132)) break L3;
            F.line = 1763;
            i_9715023 = res_10285133;
            F.line = 1763;
            l_9715009 = addInt(l_9715009, (a_9710018[chckIndx(i_9715023, 0, (a_9710018 != null ? a_9710018.length : 0)+0-1)-0] != null ? a_9710018[chckIndx(i_9715023, 0, (a_9710018 != null ? a_9710018.length : 0)+0-1)-0].length : 0));
            F.line = 80;
            res_10285133 = addInt(res_10285133, 1);
          }
      } while(false);
    } while(false);
    F.line = 1764;
    result_9710020 = nimCopy(null, mnewString(0), NTI112);
    F.line = 1765;
    if (result_9710020 != null) { result_9710020 = (result_9710020).concat(a_9710018[chckIndx(0, 0, (a_9710018 != null ? a_9710018.length : 0)+0-1)-0]); } else { result_9710020 = a_9710018[chckIndx(0, 0, (a_9710018 != null ? a_9710018.length : 0)+0-1)-0].slice(); };
    L4: do {
      F.line = 1766;
      var i_9715043 = 0;
      F.line = 66;
      var colontmp__10285139 = 0;
      F.line = 1766;
      colontmp__10285139 = (a_9710018 != null ? (a_9710018.length-1) : -1);
      F.line = 77;
      var res_10285140 = 1;
      L5: do {
        F.line = 78;
          L6: while (true) {
          if (!(res_10285140 <= colontmp__10285139)) break L6;
            F.line = 1766;
            i_9715043 = res_10285140;
            F.line = 1767;
            if (result_9710020 != null) { result_9710020 = (result_9710020).concat(sep_9710019); } else { result_9710020 = sep_9710019.slice(); };
            F.line = 1768;
            if (result_9710020 != null) { result_9710020 = (result_9710020).concat(a_9710018[chckIndx(i_9715043, 0, (a_9710018 != null ? a_9710018.length : 0)+0-1)-0]); } else { result_9710020 = a_9710018[chckIndx(i_9715043, 0, (a_9710018 != null ? a_9710018.length : 0)+0-1)-0].slice(); };
            F.line = 80;
            res_10285140 = addInt(res_10285140, 1);
          }
      } while(false);
    } while(false);
    }
    else {
      F.line = 1770;
      result_9710020 = nimCopy(null, [], NTI112);
    }
    
  framePtr = F.prev;

  return result_9710020;

}
function HEX3Aanonymous_10210023() {
  var result_10210025 = null;

  var F={procname:"testJs.:anonymous",prev:framePtr,filename:"testJs.nim",line:0};
  framePtr = F;
  BeforeRet: do {
    F.line = 85;
    var s_10210026 = nsuSplitString(makeNimstrLit("Hello vue from nim"), makeNimstrLit(" "), -1);
    F.line = 86;
    var reverse_10210043 = [];
    L1: do {
      F.line = 87;
      var i_10210056 = 0;
      F.line = 6;
      var colontmp__10285083 = 0;
      F.line = 87;
      colontmp__10285083 = (s_10210026 != null ? (s_10210026.length-1) : -1);
      F.line = 28;
      var res_10285088 = colontmp__10285083;
      L2: do {
        F.line = 29;
          L3: while (true) {
          if (!(0 <= res_10285088)) break L3;
            F.line = 87;
            i_10210056 = res_10285088;
            F.line = 88;
            var Tmp4 = nimCopy(null, s_10210026[chckIndx(i_10210056, 0, (s_10210026 != null ? s_10210026.length : 0)+0-1)-0], NTI112);
            if (reverse_10210043 != null) { reverse_10210043.push(Tmp4); } else { reverse_10210043 = [Tmp4]; };
            F.line = 31;
            res_10285088 = subInt(res_10285088, 1);
          }
      } while(false);
    } while(false);
    F.line = 89;
    result_10210025 = toJSStr(nsuJoinSep(reverse_10210043, makeNimstrLit(" ")));
    break BeforeRet;
  } while (false);
  framePtr = F.prev;

  return result_10210025;

}
function HEX3Aanonymous_10270005() {
  var F={procname:"testJs.:anonymous",prev:framePtr,filename:"testJs.nim",line:0};
  framePtr = F;
    F.line = 99;
    rawEcho(makeNimstrLit("ready state"));
  framePtr = F.prev;

  
}
jqSelector(document.body).append(("  <div id=\"app\">\n    {{ message }}\n  </div>\n  "));
var a_10050060 = [add_10050030(add_10045005(new_jobj_1282019(), makeNimstrLit("el"), makeNimstrLit("#app")), makeNimstrLit("data"), add_10045005(new_jobj_1282019(), makeNimstrLit("message"), makeNimstrLit("Hello Vue")))];
initVue(a_10050060[0]);
jqSelector(document.body).append((document.body)).append(("  <div id=\"app-2\">\n  <span v-bind:title=\"message\">\n    Hover your mouse over me for a few seconds\n    to see my dynamically bound title!\n  </span>\n  </div>\n  "));
var b_10090047 = [add_10050030(add_10045005(new_jobj_1282019(), makeNimstrLit("el"), makeNimstrLit("#app-2")), makeNimstrLit("data"), add_10090011(new_jobj_1282019(), makeNimstrLit("message"), {}.toString()))];
initVue(b_10090047[0]);
jqSelector(document.body).append((document.body)).append(("  <div id=\"app-3\">\n    <span v-if=\"seen\">Now you see me</span>\n  </div>\n  "));
var c_10130047 = [add_10050030(add_10045005(new_jobj_1282019(), makeNimstrLit("el"), makeNimstrLit("#app-3")), makeNimstrLit("data"), add_10130011(new_jobj_1282019(), makeNimstrLit("seen"), true))];
initVue(c_10130047[0]);
jqSelector(document.body).append((document.body)).append(("  <div id=\"app-4\">\n  <ol>\n    <li v-for=\"todo in todos\">\n    {{ todo.text }}\n    </li>\n  </ol>\n  </div>\n  "));
var d_10170070 = [add_10050030(add_10045005(new_jobj_1282019(), makeNimstrLit("el"), makeNimstrLit("#app-4")), makeNimstrLit("data"), add_10170034(new_jobj_1282019(), makeNimstrLit("todos"), [add_10045005(new_jobj_1282019(), makeNimstrLit("text"), makeNimstrLit("Learn nim")), add_10045005(new_jobj_1282019(), makeNimstrLit("text"), makeNimstrLit("Hack the nim"))]))];
initVue(d_10170070[0]);
jqSelector(document.body).append((document.body)).append(("  <div id=\"app-5\">\n    <p>{{ message }}</p>\n    <button v-on:click=\"reverseMessage\">Reverse Message</button>\n  </div>\n  "));
var e_10210128 = [add_10050030(add_10050030(add_10045005(new_jobj_1282019(), makeNimstrLit("el"), makeNimstrLit("#app-5")), makeNimstrLit("data"), add_10045005(new_jobj_1282019(), makeNimstrLit("message"), makeNimstrLit("Hello vue from nim"))), makeNimstrLit("methods"), add_10210092(new_jobj_1282019(), makeNimstrLit("reverseMessage"), HEX3Aanonymous_10210023))];
initVue(e_10210128[0]);
console.log((e_10210128[0].methods.reverseMessage()));
jqSelector(document.body).append(("<p>Test</p>"));
jqSelector(document).ready((HEX3Aanonymous_10270005));
