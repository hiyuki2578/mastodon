import React from 'react';
import PropTypes from 'prop-types';
import ImmutablePropTypes from 'react-immutable-proptypes';
import { autoPlayGif } from '../initial_state';

export default class Avatar extends React.PureComponent {

  static propTypes = {
    account: ImmutablePropTypes.map.isRequired,
    size: PropTypes.number.isRequired,
    style: PropTypes.object,
    inline: PropTypes.bool,
    animate: PropTypes.bool,
  };

  static defaultProps = {
    animate: autoPlayGif,
    size: 20,
    inline: false,
  };

  state = {
    hovering: false,
  };

  handleMouseEnter = () => {
    if (this.props.animate) return;
    this.setState({ hovering: true });
  }

  handleMouseLeave = () => {
    if (this.props.animate) return;
    this.setState({ hovering: false });
  }

  render () {
    const { account, size, animate, inline } = this.props;
    const { hovering } = this.state;

    const src = account.get('avatar');
    const staticSrc = account.get('avatar_static');
    const isCat = !!account.get('cat');

    let className = 'account__avatar';

    if (inline) {
      className = className + ' account__avatar-inline';
    }

    if (isCat) {
      className = className + ' account__avatar-cat';
    }

    const style = {
      ...this.props.style,
      width: `${size}px`,
      height: `${size}px`,
    };

    const innerStyle={
      backgroundSize: `${size}px ${size}px`,
    };

    if (hovering || animate) {
      innerStyle.backgroundImage = `url(${src})`;
    } else {
      innerStyle.backgroundImage = `url(${staticSrc})`;
    }

    return (
      <div
        className={className}
        onMouseEnter={this.handleMouseEnter}
        onMouseLeave={this.handleMouseLeave}
        style={style}
      >
        <div className={'account__avatar-inner'} style={innerStyle} />
      </div>
    );
  }

}
