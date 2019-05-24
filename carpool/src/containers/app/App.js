import React from 'react';
import './App.css';
import Sidebar from "react-sidebar";
import { Jumbotron, Container } from 'react-bootstrap';
import Bigarea from '../../components/bigarea/Bigarea'

import {connect} from 'react-redux'
import {addone, addoneAsync,minusone} from '../../redux/actions'

class App extends React.Component {

  componentDidMount(){
    this.props.addoneAsync(1)
  }

  changeADDHandler = (e)=> {
    this.props.addone(1)
  }

  
  changeMinusHandler = (e)=> {
    this.props.minusone(1)
  }


  render() {

    const {addnumber,minusnumber} = this.props

    return (
      <div>
        <Jumbotron fluid>
          <Container>
            <h1>{addnumber}:{minusnumber}</h1>
            <p>
              <button onClick={this.changeADDHandler}>add</button>
              <button onClick={this.changeMinusHandler}>minus</button>
            </p>
          </Container>
        </Jumbotron>

        <Bigarea></Bigarea>
      </div>
    )
  }
}

function mapStateToProps(state) {
  return {
    addnumber:state.addOneReducer.addnumber,
    minusnumber: state.minusOneReducer.minusnumber
  }
}


export default connect(
  mapStateToProps,
  {addone,addoneAsync,minusone}
)(App);
