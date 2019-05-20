import React, { Component } from 'react'
import LeftArea from '../left/LeftArea'
import RightArea from '../right/RightArea'

export default class Bigarea extends Component {
  render() {
    return (
        <div class="container-fluid">
          <div class="row content">
          <LeftArea/>
            
            <RightArea/>

          </div>
        </div>
    )
  }
}
