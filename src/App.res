@module("./logo.svg") external logo: string = "default"
%%raw(`import './App.css'`)

type mapping = {
  key: string,
  code: int,
  pattern: array<int>,
  taps: int,
  switchMode: bool,
}

@module("../mappings.json") external mappings: array<mapping> = "default"

type window_

@val external window: window_ = "window"

@send
external addEventListener: (window_, string, Dom.keyboardEvent => unit) => unit = "addEventListener"
@send
external removeEventListener: (window_, string, Dom.keyboardEvent => unit) => unit =
  "removeEventListener"

@get external keyboardKey: Dom.keyboardEvent => string = "key"

let space = mappings->Js.Array2.find(m => m.key == "space")->Belt.Option.getExn

let getRandom = (max: float) => {
  Js.Math.floor_float(Js.Math.random() *. max)->Belt.Int.fromFloat
}

let filterArray = (arr: array<mapping>, key) => {
  arr->Js.Array2.filter(value => value.key != key)
}

module Circle = {
  @react.component
  let make = (~extraMx: option<bool>=false, ~isOpen: bool) => {
    switch (extraMx, isOpen) {
    | (true, true) =>
      <div className="w-8 h-8 mx-4 rounded-full bg-white border-4 border-blue-500" />
    | (true, false) => <div className="w-8 h-8 mx-8 rounded-full bg-blue-500" />
    | (false, true) =>
      <div className="w-8 h-8 mx-2 rounded-full bg-white border-4 border-blue-500" />
    | (false, false) => <div className="w-8 h-8 mx-2 rounded-full bg-blue-500" />
    }
  }
}

module Fingers = {
  @react.component
  let make = (~value: array<int>) => {
    let c1 = value->Js.Array2.unsafe_get(0)
    let c2 = value->Js.Array2.unsafe_get(1)
    let c3 = value->Js.Array2.unsafe_get(2)
    let c4 = value->Js.Array2.unsafe_get(3)
    let c5 = value->Js.Array2.unsafe_get(4)
    <div className="flex">
      <Circle isOpen={c1 == 0} />
      <Circle isOpen={c2 == 0} />
      <Circle isOpen={c3 == 0} />
      <Circle isOpen={c4 == 0} />
      <Circle extraMx={true} isOpen={c5 == 0} />
    </div>
  }
}

@react.component
let make = () => {
  let (playArr, setPlayArr) = React.useState(_ => mappings)
  let (current, setCurrent) = React.useState(_ => None)

  Js.log(current)

  let keypress = React.useCallback4((e: Dom.keyboardEvent) => {
    let key = keyboardKey(e)
    let key = switch key {
    | " " => "space"
    | "Enter" => "enter"
    | v => v
    }

    if current == None && key == "space" {
      let currentIndex = getRandom(mappings->Js.Array2.length->Js.Int.toFloat)
      setCurrent(_ => Some(mappings->Js.Array2.unsafe_get(currentIndex)))
      setPlayArr(filterArray(_, key))
    }

    switch current {
    | Some(value)
      if value.key == key ||
      value.key == "space" && key == " " ||
      (value.key == "enter" && key == "Enter") => {
        let filteredArr = filterArray(playArr, key)

        let removedValue = filteredArr->Js.Array2.find(value => value.key == key)

        switch removedValue {
        | Some(_) => {
            Js.log3(`removed pressed ${key}`, `current value ${value.key}`, key == value.key)
            Js.Exn.raiseError("element not removed!")
          }
        | None => ()
        }

        if filteredArr->Js.Array2.length == playArr->Js.Array2.length {
          Js.Exn.raiseError("wront length!")
        }

        setPlayArr(_ => filteredArr)
        let currentIndex = getRandom(filteredArr->Js.Array2.length->Js.Int.toFloat)
        setCurrent(_ => Some(filteredArr->Js.Array2.unsafe_get(currentIndex)))
      }
    | _ => Js.log("Not match!")
    }
  }, (current, setCurrent, playArr, setPlayArr))

  React.useEffect1(() => {
    window->addEventListener("keydown", keypress)
    Some(_ => window->removeEventListener("keydown", keypress))
  }, [keypress])

  <div className="App">
    <div className="w-full h-64 bg-gray-100 flex items-center justify-center">
      {switch playArr->Js.Array2.length {
      | 0 => <> {"You're completed! Press space to start again!"->React.string} </>
      | _ =>
        switch current {
        | Some(value) =>
          <>
            <p className="mx-12"> {`${value.key}`->Js.String.toUpperCase->React.string} </p>
            <Fingers value={value.pattern} />
          </>
        | None =>
          <>
            <p className="mx-12"> {"Press space to start"->React.string} </p>
            <Fingers value={space.pattern} />
          </>
        }
      }}
    </div>
  </div>
}
